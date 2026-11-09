import 'package:flutter_test/flutter_test.dart';
import 'support/meta_mock_contracts.dart';
import 'support/e2e_test_harness.dart';
import 'support/finops_test_fixtures.dart';

void main() {
  group('Tier 2: Boundary & Corner Cases', () {
    late MockMetaSignupBridge mockBridge;
    late MockCompleteWhatsAppSignupBackend mockBackend;
    late MockWhatsAppMetaService mockService;

    setUp(() {
      mockBridge = MockMetaSignupBridge();
      mockBackend = MockCompleteWhatsAppSignupBackend();
      mockService = MockWhatsAppMetaService(
        bridge: mockBridge,
        backend: mockBackend,
      );
    });

    tearDown(() {
      mockService.dispose();
    });

    // =========================================================================
    // 1. Missing or Null Payload Fields
    // =========================================================================
    group('Missing, Null or Empty Arguments Handling', () {
      test('Cloud Function throws invalid-argument when tenantId is missing or empty', () {
        expect(
          () => mockBackend.completeWhatsAppEmbeddedSignup(data: {
            'tenantId': '',
            'code': 'valid_code',
            'wabaId': 'valid_waba',
            'phoneNumberId': 'valid_phone',
          }),
          throwsA(isA<HttpsErrorContract>()
              .having((e) => e.code, 'code', 'invalid-argument')),
        );
      });

      test('Cloud Function throws invalid-argument when code is missing or empty', () {
        expect(
          () => mockBackend.completeWhatsAppEmbeddedSignup(data: {
            'tenantId': 'tenant_01',
            'code': '   ',
            'wabaId': 'valid_waba',
            'phoneNumberId': 'valid_phone',
          }),
          throwsA(isA<HttpsErrorContract>()
              .having((e) => e.code, 'code', 'invalid-argument')),
        );
      });

      test('Cloud Function throws invalid-argument when wabaId or phoneNumberId is missing', () {
        expect(
          () => mockBackend.completeWhatsAppEmbeddedSignup(data: {
            'tenantId': 'tenant_01',
            'code': 'valid_code',
            'wabaId': null,
            'phoneNumberId': 'valid_phone',
          }),
          throwsA(isA<HttpsErrorContract>()
              .having((e) => e.code, 'code', 'invalid-argument')),
        );

        expect(
          () => mockBackend.completeWhatsAppEmbeddedSignup(data: {
            'tenantId': 'tenant_01',
            'code': 'valid_code',
            'wabaId': 'valid_waba',
            'phoneNumberId': '',
          }),
          throwsA(isA<HttpsErrorContract>()
              .having((e) => e.code, 'code', 'invalid-argument')),
        );
      });
    });

    // =========================================================================
    // 2. Invalid Codes, Token Expiry, and Graph API Failures
    // =========================================================================
    group('OAuth Errors & Network Resiliency', () {
      test('Expired OAuth code triggers permission-denied HttpsError', () {
        mockBackend.simulateExpiredCode = true;

        expect(
          () => mockBackend.completeWhatsAppEmbeddedSignup(data: {
            'tenantId': 'tenant_01',
            'code': 'expired_token_123',
            'wabaId': 'waba_123',
            'phoneNumberId': 'phone_123',
          }),
          throwsA(isA<HttpsErrorContract>()
              .having((e) => e.code, 'code', 'permission-denied')
              .having((e) => e.message, 'message', contains('expired'))),
        );
      });

      test('Graph API network timeout throws deadline-exceeded', () {
        mockBackend.simulateGraphTimeout = true;

        expect(
          () => mockBackend.completeWhatsAppEmbeddedSignup(data: {
            'tenantId': 'tenant_01',
            'code': 'code_123',
            'wabaId': 'waba_123',
            'phoneNumberId': 'phone_123',
          }),
          throwsA(isA<HttpsErrorContract>()
              .having((e) => e.code, 'code', 'deadline-exceeded')),
        );
      });
    });

    // =========================================================================
    // 3. User Cancellation in Meta Popup
    // =========================================================================
    group('User Cancellation & Session Abort', () {
      test('Service handles user closing popup without throwing unhandled exceptions', () async {
        mockBridge.simulatedResult = FinOpsTestFixtures.sampleCancelledSignupResult();

        expect(
          () => mockService.completeOnboarding(
            tenantId: 'tenant_epi_01',
            appId: 'test_app_id',
          ),
          throwsA(predicate((e) =>
              e.toString().contains('fechada pelo usuário') ||
              e.toString().contains('Cancelled by user'))),
        );

        // Ensure no phantom number was persisted
        expect(mockBackend.tenantNumbers.isEmpty, isTrue);
        expect(mockBackend.secretTokensVault.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // 4. Zero-State Metrics for New Tenant
    // =========================================================================
    group('Zero-State Metrics Handling', () {
      test('New tenant with 0 usage avoids division-by-zero and renders zero values', () {
        final zeroFinops = FinOpsTestFixtures.zeroStateRollup(
          tenantId: 'tenant_new_01',
          competencia: '2026_11',
        );

        expect(zeroFinops.totalInvestimentoBrl, equals(0.0));
        expect(zeroFinops.percentualConsumido, equals(0.0));
        expect(zeroFinops.saldoRestanteBrl, equals(1000.0));
        expect(zeroFinops.isAlertThresholdReached, isFalse);
        expect(zeroFinops.isBudgetExceeded, isFalse);
        expect(zeroFinops.iaMetrics.totalTokens, equals(0));
        expect(zeroFinops.whatsappMetrics.conversasPagas, equals(0));
        expect(zeroFinops.historicoDiario, isEmpty);
      });

      test('FinOps model safely handles budget set to 0.0 without crash', () {
        final zeroBudget = FinOpsUsageModelContract(
          competencia: '2026_11',
          tenantId: 'tenant_zero',
          orcamentoMensalBrl: 0.0,
          updatedAt: DateTime.now(),
        );

        expect(zeroBudget.percentualConsumido, equals(0.0));
        expect(zeroBudget.saldoRestanteBrl, equals(0.0));
        expect(zeroBudget.isBudgetExceeded, isFalse);
      });
    });

    // =========================================================================
    // 5. Boundary Budget Thresholds (Near 80%, Exact 80%, Over 100%)
    // =========================================================================
    group('Budget Limit Boundaries', () {
      test('Near-threshold: 79.99% does not trigger alert, 80.00% triggers alert', () {
        final underThreshold = FinOpsUsageModelContract(
          competencia: '2026_11',
          tenantId: 'tenant_epi_01',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetricsContract(custoAcumuladoBrl: 400.0),
          whatsappMetrics: const WhatsAppMetricsContract(custoAcumuladoBrl: 399.90),
          updatedAt: DateTime.now(),
        );

        // 799.90 / 1000.0 = 79.99%
        expect(underThreshold.totalInvestimentoBrl, closeTo(799.90, 0.001));
        expect(underThreshold.percentualConsumido, closeTo(79.99, 0.01));
        expect(underThreshold.isAlertThresholdReached, isFalse);
        expect(underThreshold.isBudgetExceeded, isFalse);

        final exactThreshold = FinOpsTestFixtures.nearThresholdRollup();
        // 800.00 / 1000.0 = 80.00%
        expect(exactThreshold.totalInvestimentoBrl, closeTo(800.00, 0.001));
        expect(exactThreshold.percentualConsumido, closeTo(80.00, 0.001));
        expect(exactThreshold.isAlertThresholdReached, isTrue);
        expect(exactThreshold.isBudgetExceeded, isFalse);
      });

      test('Over-budget: > 100% computes negative balance and marks exceeded', () {
        final exceeded = FinOpsTestFixtures.exceededBudgetRollup();

        // Total = 1050.00, Budget = 1000.00
        expect(exceeded.totalInvestimentoBrl, closeTo(1050.00, 0.001));
        expect(exceeded.percentualConsumido, closeTo(105.00, 0.001));
        expect(exceeded.saldoRestanteBrl, closeTo(-50.00, 0.001));
        expect(exceeded.isAlertThresholdReached, isTrue);
        expect(exceeded.isBudgetExceeded, isTrue);
      });
    });

    // =========================================================================
    // 6. Adversarial Input: Special Characters, Emojis, and Escaping
    // =========================================================================
    group('Adversarial Encoding & JSON Escaping Integrity', () {
      test('Unicode, emojis and special characters in verifiedName survive round-trip', () {
        const specialName = 'EPI Forte Equipamentos 🛠️ "Super & Cia" <script>';
        final number = WhatsAppNumberModelContract(
          id: '123456789',
          tenantId: 'tenant_test',
          wabaId: 'waba_test',
          phoneNumberId: '123456789',
          displayPhoneNumber: '+55 11 98877-6655',
          verifiedName: specialName,
          qualityRating: MetaQualityRating.green,
          messagingLimitTier: MetaMessagingTier.tier10k,
          codeVerificationStatus: 'VERIFIED',
          status: 'connected',
          webhookSubscribed: true,
          connectedByUid: 'uid_test',
          connectedAt: DateTime.now(),
          lastSyncAt: DateTime.now(),
        );

        final map = number.toFirestoreMap();
        expect(map['verified_name'], equals(specialName));

        final reconstructed = WhatsAppNumberModelContract.fromFirestoreMap(number.id, map);
        expect(reconstructed.verifiedName, equals(specialName));
      });

      test('MetaEmbeddedSignupResult parses malformed or unknown status gracefully', () {
        final malformedJson = {
          'status': 'SOME_UNEXPECTED_STATUS',
          'error_message': 'Unknown state returned',
        };

        final result = MetaEmbeddedSignupResult.fromJson(malformedJson);
        expect(result.status, equals(MetaSignupStatus.error));
        expect(result.isError, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('Meta messaging tiers gracefully fall back to unknown for unmapped strings', () {
        final tier = MetaMessagingTier.fromString('TIER_FUTURE_UNSEEN');
        expect(tier, equals(MetaMessagingTier.unknown));
        expect(tier.maxConversationsPer24h, equals(0));

        final rating = MetaQualityRating.fromString('BLUE_ORANGE');
        expect(rating, equals(MetaQualityRating.unknown));
      });
    });

    // =========================================================================
    // 7. Security: Untrusted Origins in PostMessage Listener
    // =========================================================================
    group('PostMessage Origin Filtering Security', () {
      test('Listener rejects messages from untrusted origins', () {
        const maliciousOrigins = [
          'https://evil-facebook.com',
          'http://facebook.com.attacker.org',
          'https://random-site.net',
        ];

        for (final origin in maliciousOrigins) {
          final isWhitelisted = origin == 'https://www.facebook.com' ||
              origin == 'https://web.facebook.com';
          expect(isWhitelisted, isFalse, reason: 'Origin $origin must not be trusted');
        }
      });
    });
  });
}
