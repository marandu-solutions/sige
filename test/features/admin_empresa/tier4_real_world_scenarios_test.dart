import 'package:flutter_test/flutter_test.dart';
import 'support/e2e_test_harness.dart';
import 'support/finops_test_fixtures.dart';

void main() {
  group('Tier 4: Real-World Scenarios', () {
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
    // Scenario 1: Multi-Number Enterprise Tenant Management
    // =========================================================================
    test('Scenario 1: Multi-Number Enterprise Tenant with Independent AI Toggles', () async {
      const tenantId = FinOpsTestFixtures.tenantEpiId;
      final num1 = FinOpsTestFixtures.epiPrimaryNumber();
      final num2 = FinOpsTestFixtures.epiSecondaryNumber();

      mockService.seedInitialData(numbers: [num1, num2]);

      // Verify initial state: num1 has IA true, num2 has IA false
      var currentNumbers = await mockService.watchConnectedNumbers(tenantId).first;
      expect(currentNumbers.length, equals(2));

      final activeNum1 = currentNumbers.firstWhere((n) => n.id == num1.id);
      final activeNum2 = currentNumbers.firstWhere((n) => n.id == num2.id);

      expect(activeNum1.iaAtivaNesteNumero, isTrue);
      expect(activeNum1.isDefault, isTrue);
      expect(activeNum2.iaAtivaNesteNumero, isFalse);
      expect(activeNum2.isDefault, isFalse);

      // Toggle IA ON for num2
      await mockService.toggleIa(tenantId: tenantId, phoneNumberId: num2.id, enabled: true);

      currentNumbers = await mockService.watchConnectedNumbers(tenantId).first;
      expect(currentNumbers.firstWhere((n) => n.id == num2.id).iaAtivaNesteNumero, isTrue);
      // num1 must remain unaffected
      expect(currentNumbers.firstWhere((n) => n.id == num1.id).iaAtivaNesteNumero, isTrue);

      // Remove secondary number (Unlink)
      await mockService.removeNumber(tenantId: tenantId, phoneNumberId: num2.id);

      currentNumbers = await mockService.watchConnectedNumbers(tenantId).first;
      expect(currentNumbers.length, equals(1));
      expect(currentNumbers.first.id, equals(num1.id));
      expect(currentNumbers.first.isDefault, isTrue);
    });

    // =========================================================================
    // Scenario 2: Budget Threshold Escalation Lifecycle
    // =========================================================================
    test('Scenario 2: FinOps Budget Escalation (Healthy -> Warning -> Exceeded -> Restored)', () async {
      const tenantId = FinOpsTestFixtures.tenantEpiId;
      const competencia = '2026_11';

      // Stage 1: Healthy at start of month (R$ 562.80 of R$ 1,500.00 = 37.5%)
      mockService.seedInitialData(
        finops: FinOpsTestFixtures.standardEpiNovemberRollup(),
      );

      var finops = await mockService.watchUsageMetrics(tenantId, competencia).first;
      expect(finops.percentualConsumido, closeTo(37.52, 0.01));
      expect(finops.isAlertThresholdReached, isFalse);
      expect(finops.isBudgetExceeded, isFalse);

      // Stage 2: Spike pushes usage over 80% (Warning)
      // Add R$ 680.00 -> Total: R$ 1,242.80 (82.85%)
      await mockService.recordTelemetryUsage(
        tenantId: tenantId,
        competencia: competencia,
        additionalIaCost: 280.00,
        additionalWaCost: 400.00,
        additionalMsgs: 2000,
      );

      finops = await mockService.watchUsageMetrics(tenantId, competencia).first;
      expect(finops.totalInvestimentoBrl, closeTo(1242.80, 0.01));
      expect(finops.percentualConsumido, closeTo(82.85, 0.05));
      expect(finops.isAlertThresholdReached, isTrue);
      expect(finops.isBudgetExceeded, isFalse);

      // Stage 3: Major campaign pushes usage over 100% (Critical Exceeded)
      // Add R$ 350.00 -> Total: R$ 1,592.80 (106.18%)
      await mockService.recordTelemetryUsage(
        tenantId: tenantId,
        competencia: competencia,
        additionalIaCost: 150.00,
        additionalWaCost: 200.00,
        additionalMsgs: 1200,
      );

      finops = await mockService.watchUsageMetrics(tenantId, competencia).first;
      expect(finops.totalInvestimentoBrl, closeTo(1592.80, 0.01));
      expect(finops.percentualConsumido, closeTo(106.18, 0.05));
      expect(finops.isBudgetExceeded, isTrue);
      expect(finops.saldoRestanteBrl, closeTo(-92.80, 0.01));

      // Stage 4: Executive raises budget to R$ 2,500.00 (Restored to Healthy)
      await mockService.updateMonthlyBudget(
        tenantId: tenantId,
        competencia: competencia,
        newBudgetBrl: 2500.00,
      );

      finops = await mockService.watchUsageMetrics(tenantId, competencia).first;
      // 1592.80 / 2500.00 = 63.71% < 80%
      expect(finops.orcamentoMensalBrl, equals(2500.00));
      expect(finops.percentualConsumido, closeTo(63.71, 0.05));
      expect(finops.isAlertThresholdReached, isFalse);
      expect(finops.isBudgetExceeded, isFalse);
      expect(finops.saldoRestanteBrl, closeTo(907.20, 0.01));
    });

    // =========================================================================
    // Scenario 3: Multi-Tenant Concurrency and Strict Isolation
    // =========================================================================
    test('Scenario 3: Multi-Tenant Concurrency and Zero Data Leakage', () async {
      const tenantA = FinOpsTestFixtures.tenantEpiId;
      const tenantB = FinOpsTestFixtures.tenantSolarId;

      final epiNumber = FinOpsTestFixtures.epiPrimaryNumber();
      final solarNumber = FinOpsTestFixtures.solarPrimaryNumber();

      mockService.seedInitialData(numbers: [epiNumber, solarNumber]);

      // Tenant A only sees Tenant A's numbers
      final numbersA = await mockService.watchConnectedNumbers(tenantA).first;
      expect(numbersA.length, equals(1));
      expect(numbersA.first.id, equals(epiNumber.id));
      expect(numbersA.any((n) => n.id == solarNumber.id), isFalse);

      // Tenant B only sees Tenant B's numbers
      final numbersB = await mockService.watchConnectedNumbers(tenantB).first;
      expect(numbersB.length, equals(1));
      expect(numbersB.first.id, equals(solarNumber.id));
      expect(numbersB.any((n) => n.id == epiNumber.id), isFalse);
    });

    // =========================================================================
    // Scenario 4: Stepper Flow Retry Lifecycle After User Cancellation
    // =========================================================================
    test('Scenario 4: Stepper Retry Lifecycle After Initial User Cancellation', () async {
      const tenantId = FinOpsTestFixtures.tenantEpiId;

      // First attempt: user cancels popup
      mockBridge.simulatedResult = FinOpsTestFixtures.sampleCancelledSignupResult();

      try {
        await mockService.completeOnboarding(
          tenantId: tenantId,
          appId: 'test_app_id',
        );
        fail('Should have failed due to cancellation');
      } catch (e) {
        expect(e.toString(), contains('fechada pelo usuário'));
      }

      // Dialog remains open with "Tentar Novamente" button
      // Second attempt: user succeeds
      mockBridge.simulatedResult = FinOpsTestFixtures.sampleSuccessSignupResult();

      final onboarded = await mockService.completeOnboarding(
        tenantId: tenantId,
        appId: 'test_app_id',
      );

      expect(onboarded.status, equals('connected'));
      expect(onboarded.webhookSubscribed, isTrue);
      expect(mockBridge.launchCallCount, equals(2));
    });
  });
}
