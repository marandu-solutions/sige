import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/models/usage_finops_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/whatsapp_finops_providers.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_bridge.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

class MockBridgeForProviders implements MetaSignupBridge {
  MetaEmbeddedSignupResult result;
  MockBridgeForProviders(this.result);

  @override
  bool get isSupported => true;

  @override
  String get platformName => 'mock_bridge';

  @override
  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    return result;
  }
}

void main() {
  group('selectedCompetenciaProvider Tests', () {
    test('Defaults to current calendar month in YYYY_MM format', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final competencia =
          container.read(selectedCompetenciaProvider('tenant_epi_01'));
      final now = DateTime.now();
      final expected = '${now.year}_${now.month.toString().padLeft(2, '0')}';

      expect(competencia, equals(expected));
    });

    test('State is scoped per tenantId', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedCompetenciaProvider('tenant_epi_01').notifier)
          .state = '2026_10';

      expect(
        container.read(selectedCompetenciaProvider('tenant_epi_01')),
        equals('2026_10'),
      );

      final now = DateTime.now();
      final expectedDefault =
          '${now.year}_${now.month.toString().padLeft(2, '0')}';
      expect(
        container.read(selectedCompetenciaProvider('tenant_solar_02')),
        equals(expectedDefault),
      );
    });
  });

  group('FinOps Budget Alert and Exceeded Providers Tests', () {
    test('finopsBudgetAlertProvider returns false when data is null or below threshold', () async {
      final container = ProviderContainer(
        overrides: [
          usageFinopsStreamProvider('tenant_test').overrideWith((ref) {
            return Stream.value(UsageFinopsModel.zeroState(
              tenantId: 'tenant_test',
              competencia: '2026_11',
            ));
          }),
        ],
      );
      addTearDown(container.dispose);

      // Pump stream
      await container.read(usageFinopsStreamProvider('tenant_test').future);

      final isAlert = container.read(finopsBudgetAlertProvider('tenant_test'));
      final isExceeded = container.read(finopsBudgetExceededProvider('tenant_test'));

      expect(isAlert, isFalse);
      expect(isExceeded, isFalse);
    });

    test('finopsBudgetAlertProvider triggers when 80% threshold is reached', () async {
      final modelAt80Percent = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: 'tenant_test',
        orcamentoMensalBrl: 1000.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 400.0),
        whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 400.0),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          usageFinopsStreamProvider('tenant_test').overrideWith((ref) {
            return Stream.value(modelAt80Percent);
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(usageFinopsStreamProvider('tenant_test').future);

      final isAlert = container.read(finopsBudgetAlertProvider('tenant_test'));
      final isExceeded = container.read(finopsBudgetExceededProvider('tenant_test'));

      expect(isAlert, isTrue);
      expect(isExceeded, isFalse);
    });

    test('finopsBudgetExceededProvider triggers when spending exceeds 100%', () async {
      final exceededModel = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: 'tenant_test',
        orcamentoMensalBrl: 1000.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 600.0),
        whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 500.0),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          usageFinopsStreamProvider('tenant_test').overrideWith((ref) {
            return Stream.value(exceededModel);
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(usageFinopsStreamProvider('tenant_test').future);

      final isAlert = container.read(finopsBudgetAlertProvider('tenant_test'));
      final isExceeded = container.read(finopsBudgetExceededProvider('tenant_test'));

      expect(isAlert, isTrue);
      expect(isExceeded, isTrue);
    });
  });

  group('EmbeddedSignupState & EmbeddedSignupController Tests', () {
    test('EmbeddedSignupState default construction and inspect getters', () {
      const state = EmbeddedSignupState();
      expect(state.step, equals(MetaSignupStep.idle));
      expect(state.isBusy, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.connectedNumber, isNull);
      expect(state.isCompleted, isFalse);
      expect(state.isCancelled, isFalse);
      expect(state.isError, isFalse);

      final copy = state.copyWith(
        step: MetaSignupStep.completed,
        isBusy: false,
      );
      expect(copy.isCompleted, isTrue);
    });

    test('EmbeddedSignupController handles user cancellation', () async {
      final bridge = MockBridgeForProviders(
        MetaEmbeddedSignupResult.cancelled(reason: 'Closed by user'),
      );
      final service = WhatsAppMetaService(bridge: bridge);
      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: 'app_123',
      );

      expect(controller.state.isCancelled, isTrue);
      expect(controller.state.isBusy, isFalse);
      expect(controller.state.errorMessage, contains('Closed by user'));
    });

    test('EmbeddedSignupController handles error and reset', () async {
      final bridge = MockBridgeForProviders(
        MetaEmbeddedSignupResult.error('Popup blocked'),
      );
      final service = WhatsAppMetaService(bridge: bridge);
      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: 'app_123',
      );

      expect(controller.state.isError, isTrue);
      expect(controller.state.isBusy, isFalse);
      expect(controller.state.errorMessage, contains('Popup blocked'));

      controller.reset();
      expect(controller.state.step, equals(MetaSignupStep.idle));
      expect(controller.state.errorMessage, isNull);
    });
  });
}
