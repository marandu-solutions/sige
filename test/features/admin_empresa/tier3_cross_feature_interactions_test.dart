import 'package:flutter_test/flutter_test.dart';
import 'support/meta_mock_contracts.dart';
import 'support/e2e_test_harness.dart';
import 'support/finops_test_fixtures.dart';

void main() {
  group('Tier 3: Cross-Feature Interactions Pipeline', () {
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
    // Pipeline 1: Onboarding -> Backend Vaulting -> Routing Index -> Stream
    // =========================================================================
    test('Cross-Feature Pipeline 1: Onboarding -> Backend Security Segregation -> Stream Update', () async {
      const tenantId = FinOpsTestFixtures.tenantEpiId;
      final initialSignup = FinOpsTestFixtures.sampleSuccessSignupResult();
      mockBridge.simulatedResult = initialSignup;

      // 1. User completes onboarding via service
      final number = await mockService.completeOnboarding(
        tenantId: tenantId,
        appId: '1234567890',
        configId: 'cfg_signup_01',
      );

      expect(number.phoneNumberId, equals(initialSignup.phoneNumberId));
      expect(number.wabaId, equals(initialSignup.wabaId));
      expect(number.tenantId, equals(tenantId));

      // 2. Verify backend atomic vaulting: tenant_secrets
      final vaultKey = '$tenantId/${initialSignup.phoneNumberId}';
      expect(mockBackend.secretTokensVault.containsKey(vaultKey), isTrue);
      final vaultDoc = mockBackend.secretTokensVault[vaultKey]!;
      expect(vaultDoc.accessToken, isNotEmpty);
      expect(vaultDoc.scopes, contains('whatsapp_business_messaging'));

      // 3. Verify backend atomic index: whatsapp_routing O(1)
      final routingDoc = mockBackend.globalRoutingIndex[initialSignup.phoneNumberId!];
      expect(routingDoc, isNotNull);
      expect(routingDoc!.tenantId, equals(tenantId));
      expect(routingDoc.active, isTrue);

      // 4. Verify public number document in tenant subcollection
      final publicDoc = mockBackend.tenantNumbers[vaultKey];
      expect(publicDoc, isNotNull);
      expect(publicDoc!.webhookSubscribed, isTrue);

      // 5. Verify reactive stream emitted the new number
      final streamNumbers = await mockService.watchConnectedNumbers(tenantId).first;
      expect(streamNumbers.any((n) => n.phoneNumberId == initialSignup.phoneNumberId), isTrue);
    });

    // =========================================================================
    // Pipeline 2: Webhook Routing Index O(1) Resolution
    // =========================================================================
    test('Cross-Feature Pipeline 2: Global Routing Index resolves tenant in O(1)', () async {
      // Seed routing index with multiple tenants
      mockBackend.globalRoutingIndex['109283746511223'] = GlobalRoutingRecordContract(
        phoneNumberId: '109283746511223',
        wabaId: '998877665544332',
        tenantId: FinOpsTestFixtures.tenantEpiId,
        updatedAt: DateTime.now(),
      );

      mockBackend.globalRoutingIndex['332211445566'] = GlobalRoutingRecordContract(
        phoneNumberId: '332211445566',
        wabaId: '554433221100998',
        tenantId: FinOpsTestFixtures.tenantSolarId,
        updatedAt: DateTime.now(),
      );

      // Simulate incoming webhook from Meta containing phone_number_id
      String resolveTenantForWebhook(String incomingPhoneNumberId) {
        final record = mockBackend.globalRoutingIndex[incomingPhoneNumberId];
        if (record == null || !record.active) {
          throw Exception('Unknown or inactive WhatsApp number');
        }
        return record.tenantId;
      }

      final resolvedEpi = resolveTenantForWebhook('109283746511223');
      expect(resolvedEpi, equals(FinOpsTestFixtures.tenantEpiId));

      final resolvedSolar = resolveTenantForWebhook('332211445566');
      expect(resolvedSolar, equals(FinOpsTestFixtures.tenantSolarId));

      expect(() => resolveTenantForWebhook('999999999999'), throwsException);
    });

    // =========================================================================
    // Pipeline 3: Number Registration -> FinOps Telemetry -> Budget Check
    // =========================================================================
    test('Cross-Feature Pipeline 3: Number Onboarding -> Telemetry Update -> Budget Health Check', () async {
      const tenantId = FinOpsTestFixtures.tenantEpiId;
      const competencia = '2026_11';

      // 1. Initial State: Seed with initial FinOps rollup
      final initialRollup = FinOpsTestFixtures.standardEpiNovemberRollup();
      mockService.seedInitialData(
        numbers: [FinOpsTestFixtures.epiPrimaryNumber()],
        finops: initialRollup,
      );

      var finopsCurrent = await mockService.watchUsageMetrics(tenantId, competencia).first;
      expect(finopsCurrent.totalInvestimentoBrl, closeTo(562.80, 0.01));
      expect(finopsCurrent.isAlertThresholdReached, isFalse);

      // 2. High traffic burst: add R$ 700.00 in Meta messages & IA
      await mockService.recordTelemetryUsage(
        tenantId: tenantId,
        competencia: competencia,
        additionalIaCost: 300.00,
        additionalWaCost: 400.00,
        additionalMsgs: 2500,
      );

      finopsCurrent = await mockService.watchUsageMetrics(tenantId, competencia).first;
      // New total: 562.80 + 700.00 = 1262.80 (Budget: 1500.00 -> 84.18% > 80% threshold!)
      expect(finopsCurrent.totalInvestimentoBrl, closeTo(1262.80, 0.01));
      expect(finopsCurrent.percentualConsumido, closeTo(84.18, 0.05));
      expect(finopsCurrent.isAlertThresholdReached, isTrue);
      expect(finopsCurrent.isBudgetExceeded, isFalse);
      expect(finopsCurrent.saldoRestanteBrl, closeTo(237.20, 0.01));
    });

    // =========================================================================
    // Pipeline 4: Budget Adjustment Dynamically Resets Health
    // =========================================================================
    test('Cross-Feature Pipeline 4: Budget Adjustment Dynamically Restores Health', () async {
      const tenantId = FinOpsTestFixtures.tenantEpiId;
      const competencia = '2026_11';

      // Seed with near threshold rollup (800 / 1000 = 80%)
      mockService.seedInitialData(
        finops: FinOpsTestFixtures.nearThresholdRollup(),
      );

      var finopsCurrent = await mockService.watchUsageMetrics(tenantId, competencia).first;
      expect(finopsCurrent.isAlertThresholdReached, isTrue);

      // Manager increases monthly budget from R$ 1,000.00 to R$ 2,000.00
      await mockService.updateMonthlyBudget(
        tenantId: tenantId,
        competencia: competencia,
        newBudgetBrl: 2000.00,
      );

      finopsCurrent = await mockService.watchUsageMetrics(tenantId, competencia).first;
      // New percentage: 800 / 2000 = 40.0% -> alert reset!
      expect(finopsCurrent.orcamentoMensalBrl, equals(2000.00));
      expect(finopsCurrent.percentualConsumido, closeTo(40.0, 0.01));
      expect(finopsCurrent.isAlertThresholdReached, isFalse);
      expect(finopsCurrent.saldoRestanteBrl, closeTo(1200.00, 0.01));
    });
  });
}
