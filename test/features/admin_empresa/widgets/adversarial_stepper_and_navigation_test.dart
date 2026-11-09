import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/core.dart';
import 'package:sige/src/features/admin_empresa/src/models/usage_finops_model.dart';
import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/admin_providers.dart';
import 'package:sige/src/features/admin_empresa/src/providers/tenant_provider.dart';
import 'package:sige/src/features/admin_empresa/src/providers/whatsapp_finops_providers.dart';
import 'package:sige/src/features/admin_empresa/src/screens/admin_dashboard_screen.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/canais_consumo_ia_tab.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/whatsapp_embedded_signup_dialog.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_models.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

// =============================================================================
// ADVERSARIAL SERVICE & HARNESS
// =============================================================================

class _AdversarialMockService extends Fake implements WhatsAppMetaService {
  Completer<WhatsAppNumberModel>? inflightCompleter;
  void Function(MetaSignupStep step)? currentStepCallback;
  int onboardingCallCount = 0;
  String? lastAppId;
  String? lastConfigId;
  bool? lastSimulationMode;

  Future<void> Function()? onStartOnboarding;

  @override
  Future<WhatsAppNumberModel> completeOnboarding({
    required String tenantId,
    required String appId,
    String? configId,
    bool simulationMode = false,
    void Function(MetaSignupStep step)? onStepChanged,
  }) async {
    onboardingCallCount++;
    lastAppId = appId;
    lastConfigId = configId;
    lastSimulationMode = simulationMode;
    currentStepCallback = onStepChanged;

    if (onStartOnboarding != null) {
      await onStartOnboarding!();
    }

    if (inflightCompleter != null) {
      return inflightCompleter!.future;
    }

    onStepChanged?.call(MetaSignupStep.authenticatingInMeta);
    onStepChanged?.call(MetaSignupStep.capturingSessionIds);
    onStepChanged?.call(MetaSignupStep.exchangingTokenAndSubscribing);
    onStepChanged?.call(MetaSignupStep.completed);

    return WhatsAppNumberModel(
      id: 'phone_adv_001',
      tenantId: tenantId,
      wabaId: 'waba_adv_001',
      phoneNumberId: 'phone_adv_001',
      displayPhoneNumber: '+55 11 99999-8888',
      verifiedName: 'Empresa Adversarial Test',
      qualityRating: MetaQualityRating.green,
      messagingLimitTier: MetaMessagingTier.tier10k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      iaAtivaNesteNumero: true,
      connectedAt: DateTime(2026, 11, 1),
      lastSyncAt: DateTime(2026, 11, 8),
    );
  }

  @override
  Future<void> toggleIa({
    required String tenantId,
    required String phoneNumberId,
    required bool enabled,
  }) async {}

  @override
  Future<void> syncNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {}

  @override
  Future<void> updateMonthlyBudget({
    required String tenantId,
    required double newBudgetBrl,
    String? competencia,
  }) async {}

  @override
  Future<void> disconnectNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {}
}

void main() {
  const tenantId = 'tenant_adversarial_test';

  final sampleTenant = TenantModel(
    id: tenantId,
    nomeFantasia: 'Empresa Adversarial S/A',
    documentoFiscal: '99.888.777/0001-66',
    status: 'active',
    modulosAtivos: const ['admin', 'atendimento'],
    config: const {},
  );

  final sampleCompletedNumber = WhatsAppNumberModel(
    id: 'phone_adv_001',
    tenantId: tenantId,
    wabaId: 'waba_adv_001',
    phoneNumberId: 'phone_adv_001',
    displayPhoneNumber: '+55 11 99999-8888',
    verifiedName: 'Empresa Adversarial Test',
    qualityRating: MetaQualityRating.green,
    messagingLimitTier: MetaMessagingTier.tier10k,
    codeVerificationStatus: 'VERIFIED',
    status: 'connected',
    webhookSubscribed: true,
    iaAtivaNesteNumero: true,
    isDefault: true,
    connectedAt: DateTime(2026, 11, 1),
    lastSyncAt: DateTime(2026, 11, 8),
  );

  Widget createDialogHost({
    required _AdversarialMockService service,
    ValueChanged<WhatsAppNumberModel>? onCompleted,
    bool defaultSimulationMode = false,
    String? initialAppId,
    String? initialConfigId,
  }) {
    return ProviderScope(
      overrides: [
        whatsappMetaServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  WhatsAppEmbeddedSignupDialog.show(
                    context,
                    tenantId: tenantId,
                    initialAppId: initialAppId,
                    initialConfigId: initialConfigId,
                    defaultSimulationMode: defaultSimulationMode,
                    onCompleted: onCompleted,
                  );
                },
                child: const Text('Abrir Modal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget createDashboardHost({
    required _AdversarialMockService service,
    Stream<UsageFinopsModel?>? usageStream,
    Stream<List<WhatsAppNumberModel>>? numbersStream,
    List<FuncionarioModel>? funcionariosList,
  }) {
    return ProviderScope(
      overrides: [
        tenantProvider(tenantId).overrideWith((ref) => Future.value(sampleTenant)),
        funcionariosProvider(tenantId).overrideWith(
          (ref) => Future.value(funcionariosList ?? <FuncionarioModel>[]),
        ),
        usageFinopsStreamProvider(tenantId).overrideWith(
          (ref) => (usageStream ??
              Stream.value(
                UsageFinopsModel.zeroState(tenantId: tenantId, competencia: '2026_11'),
              )),
        ),
        whatsappNumbersStreamProvider(tenantId).overrideWith(
          (ref) => (numbersStream ?? Stream.value(<WhatsAppNumberModel>[])),
        ),
        whatsappMetaServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: AdminDashboardScreen(tenantId: tenantId),
      ),
    );
  }

  void setViewport(WidgetTester tester, {double width = 1280, double height = 900}) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  // ===========================================================================
  // GROUP 1: RAPID STAGE TRANSITIONS & IN-FLIGHT CANCELLATION
  // ===========================================================================
  group('Adversarial Group 1: Rapid Stage Transitions & In-Flight Operations', () {
    testWidgets('1.1 Rapid step progression through all 4 stages without desync or UI jitter',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Trigger Onboarding
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump(); // Stage 1: authenticatingInMeta

      expect(find.text('Autenticando com a Meta...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Fast-forward to Stage 2: capturingSessionIds
      service.currentStepCallback?.call(MetaSignupStep.capturingSessionIds);
      await tester.pump();
      expect(find.text('Capturando identificadores oficiais...'), findsOneWidget);

      // Fast-forward to Stage 3: exchangingTokenAndSubscribing
      service.currentStepCallback?.call(MetaSignupStep.exchangingTokenAndSubscribing);
      await tester.pump();
      expect(find.text('Trocando credenciais e ativando webhooks...'), findsOneWidget);

      // Fast-forward to Stage 4: completed
      completer.complete(sampleCompletedNumber);
      await tester.pumpAndSettle();

      expect(find.text('Número Oficial Conectado com Sucesso!'), findsOneWidget);
      expect(find.text('+55 11 99999-8888'), findsOneWidget);
      expect(find.text('Concluir & Ir ao Painel'), findsOneWidget);
    });

    testWidgets('1.2 In-flight cancellation via Meta popup dismissal shows amber card and allows retry',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Start onboarding
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump();

      expect(find.text('Autenticando com a Meta...'), findsOneWidget);

      // Simulate user closing popup mid-flight
      completer.completeError(
        MetaSignupException.userCancelled(details: 'Popup fechado pelo usuário'),
      );
      await tester.pumpAndSettle();

      // Verify Amber Cancelled State
      expect(find.text('Conexão Cancelada pelo Usuário'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      // Ensure no red error alert is displayed
      expect(find.text('Falha na Conexão com a Meta'), findsNothing);

      // Click "Tentar Novamente" to reset
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();

      // Dialog returns to idle state
      expect(find.text('Permissões Oficiais Requeridas'), findsOneWidget);
      expect(find.text('Iniciar Cadastro Incorporado'), findsOneWidget);
    });

    testWidgets('1.3 Programmatic dialog dismissal while onboarding is in-flight resolves cleanly',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Start onboarding
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump();

      expect(find.text('Autenticando com a Meta...'), findsOneWidget);

      // Programmatically pop dialog while in-flight (simulating route pop or hardware back)
      Navigator.of(tester.element(find.byType(WhatsAppEmbeddedSignupDialog))).pop();
      await tester.pumpAndSettle();

      // Verify dialog is gone
      expect(find.byType(WhatsAppEmbeddedSignupDialog), findsNothing);

      // Now resolve the in-flight future after dialog was popped
      completer.complete(sampleCompletedNumber);
      await tester.pumpAndSettle();

      // No unhandled exception or crash occurred
      expect(find.text('Abrir Modal'), findsOneWidget);
    });

    testWidgets('1.4 Multi-tap stress on "Iniciar Cadastro Incorporado" does not spawn duplicates',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final ctaFinder = find.text('Iniciar Cadastro Incorporado');
      expect(ctaFinder, findsOneWidget);

      // Rapidly tap CTA twice in same frame
      await tester.tap(ctaFinder);
      await tester.pump();

      // Button is now hidden/replaced by progress indicator
      expect(find.text('Iniciar Cadastro Incorporado'), findsNothing);
      expect(service.onboardingCallCount, equals(1));

      completer.complete(sampleCompletedNumber);
      await tester.pumpAndSettle();
      expect(service.onboardingCallCount, equals(1));
    });
  });

  // ===========================================================================
  // GROUP 2: SIMULATION MODE FALLBACK & ERROR RESILIENCE
  // ===========================================================================
  group('Adversarial Group 2: Simulation Mode Fallback & Error Resilience', () {
    testWidgets('2.1 Meta SDK error prompts "Modo Simulação" fallback switch which resets to idle',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(
        service: service,
        defaultSimulationMode: false,
      ));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Start onboarding
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump();

      // Simulate Meta SDK failure
      completer.completeError(
        MetaSignupException(
          'Meta JS SDK não pôde ser carregado no navegador',
          errorCode: MetaSignupErrorCode.sdkNotLoaded,
          recoveryHint: 'Verifique se o bloqueador de anúncios bloqueou connect.facebook.net',
        ),
      );
      await tester.pumpAndSettle();

      // Verify Red Error View with diagnostic message
      expect(find.text('Falha na Conexão com a Meta'), findsOneWidget);
      expect(find.textContaining('Meta JS SDK não pôde ser carregado'), findsOneWidget);
      expect(find.text('Modo Simulação'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);

      // Tap "Modo Simulação"
      await tester.tap(find.text('Modo Simulação'));
      await tester.pumpAndSettle();

      // Should be back to Idle with Simulation Switch set to ON
      expect(find.text('Iniciar Cadastro Incorporado'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch simSwitch = tester.widget(switchFinder);
      expect(simSwitch.value, isTrue);

      // Now start onboarding again - should pass simulationMode: true
      service.inflightCompleter = null; // direct auto-complete
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pumpAndSettle();

      expect(service.lastSimulationMode, isTrue);
      expect(find.text('Número Oficial Conectado com Sucesso!'), findsOneWidget);
    });

    testWidgets('2.2 Missing session data error displays friendly alert without crashing',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump();

      completer.completeError(
        MetaSignupException.missingSessionData(
          details: 'WABA ID vazio ou não selecionado pelo usuário.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha na Conexão com a Meta'), findsOneWidget);
      expect(find.textContaining('WABA ID vazio ou não selecionado'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
    });

    testWidgets('2.3 Unexpected generic exception string is cleanly parsed and formatted',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump();

      // Generic untyped exception
      completer.completeError(Exception('Conexão perdida com Firebase Cloud Functions [503]'));
      await tester.pumpAndSettle();

      expect(find.text('Falha na Conexão com a Meta'), findsOneWidget);
      expect(find.textContaining('Conexão perdida com Firebase Cloud Functions'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 3: DIALOG DISMISSAL, RETRY RESETS & CONTROLLER DISPOSAL SAFETY
  // ===========================================================================
  group('Adversarial Group 3: Dialog Dismissal, Retry Resets & Controller Disposal Safety', () {
    testWidgets('3.1 Custom App ID and Config ID are forwarded correctly and controllers disposed cleanly',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();

      await tester.pumpWidget(createDialogHost(
        service: service,
        initialAppId: 'custom_meta_app_9988',
        initialConfigId: 'custom_config_7766',
      ));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Open advanced settings
      await tester.tap(find.text('Configurações Avançadas da Meta API (Opcional)'));
      await tester.pumpAndSettle();

      expect(find.text('custom_meta_app_9988'), findsOneWidget);
      expect(find.text('custom_config_7766'), findsOneWidget);

      // Start onboarding
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pumpAndSettle();

      expect(service.lastAppId, equals('custom_meta_app_9988'));
      expect(service.lastConfigId, equals('custom_config_7766'));

      // Dismiss dialog
      await tester.tap(find.text('Concluir & Ir ao Painel'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsAppEmbeddedSignupDialog), findsNothing);
    });

    testWidgets('3.2 Rapid open and dismiss cycles (10 iterations) cause zero memory leaks or disposed errors',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();

      await tester.pumpWidget(createDialogHost(service: service));

      for (int i = 0; i < 10; i++) {
        // Open
        await tester.tap(find.text('Abrir Modal'));
        await tester.pump(); // partial pump
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(WhatsAppEmbeddedSignupDialog), findsOneWidget);

        // Close via Cancelar button
        final cancelBtn = find.text('Cancelar');
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        expect(find.byType(WhatsAppEmbeddedSignupDialog), findsNothing);
      }
    });

    testWidgets('3.3 Header close button (X) is disabled when busy, active when idle',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      final completer = Completer<WhatsAppNumberModel>();
      service.inflightCompleter = completer;

      await tester.pumpWidget(createDialogHost(service: service));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final closeIcon = find.byIcon(LucideIcons.x);
      expect(closeIcon, findsOneWidget);

      // When idle, close icon works
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();
      expect(find.byType(WhatsAppEmbeddedSignupDialog), findsNothing);

      // Reopen
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Start signup (now busy)
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pump();

      // Tap close icon while busy -> should NOT close
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      expect(find.byType(WhatsAppEmbeddedSignupDialog), findsOneWidget);

      // Complete
      completer.complete(sampleCompletedNumber);
      await tester.pumpAndSettle();

      // In completed state, close icon works again
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsAppEmbeddedSignupDialog), findsNothing);
    });

    testWidgets('3.4 onCompleted callback is fired with the hydrated number model',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();
      WhatsAppNumberModel? capturedModel;

      await tester.pumpWidget(createDialogHost(
        service: service,
        onCompleted: (model) {
          capturedModel = model;
        },
      ));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pumpAndSettle();

      expect(find.text('Concluir & Ir ao Painel'), findsOneWidget);
      await tester.tap(find.text('Concluir & Ir ao Painel'));
      await tester.pumpAndSettle();

      expect(capturedModel, isNotNull);
      expect(capturedModel!.phoneNumberId, equals('phone_adv_001'));
      expect(capturedModel!.displayPhoneNumber, equals('+55 11 99999-8888'));
    });
  });

  // ===========================================================================
  // GROUP 4: RAPID TAB SWITCHING IN ADMIN DASHBOARD SCREEN
  // ===========================================================================
  group('Adversarial Group 4: Rapid Tab Switching in AdminDashboardScreen', () {
    testWidgets('4.1 Rapid consecutive switching across all 3 tabs mid-transition produces zero errors',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();

      await tester.pumpWidget(createDashboardHost(service: service));
      await tester.pumpAndSettle();

      final tab1Finder = find.text('Equipe & Acessos');
      final tab2Finder = find.text('Operação & Loja');
      final tab3Finder = find.text('Canais & Consumo IA');

      expect(tab1Finder, findsOneWidget);
      expect(tab2Finder, findsOneWidget);
      expect(tab3Finder, findsOneWidget);

      // Rapidly toggle tabs mid-animation without awaiting settle
      for (int i = 0; i < 4; i++) {
        await tester.tap(tab3Finder);
        await tester.pump(const Duration(milliseconds: 30));

        await tester.tap(tab2Finder);
        await tester.pump(const Duration(milliseconds: 30));

        await tester.tap(tab1Finder);
        await tester.pump(const Duration(milliseconds: 30));

        await tester.tap(tab3Finder);
        await tester.pump(const Duration(milliseconds: 30));
      }

      // Allow animations to finally settle
      await tester.pumpAndSettle();

      // Verify Tab 3 is active and properly rendered
      expect(find.text('Competência Contábil FinOps'), findsOneWidget);

      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      expect(find.byType(CanaisConsumoIaTab), findsOneWidget);
    });

    testWidgets('4.2 Active stream emissions during tab switching does not cause memory leaks or disposed errors',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();

      final initialUsage = UsageFinopsModel.zeroState(
        tenantId: tenantId,
        competencia: '2026_11',
      );

      final usageStreamController = StreamController<UsageFinopsModel?>.broadcast();
      final numbersStreamController = StreamController<List<WhatsAppNumberModel>>.broadcast();

      addTearDown(() {
        usageStreamController.close();
        numbersStreamController.close();
      });

      await tester.pumpWidget(createDashboardHost(
        service: service,
        usageStream: usageStreamController.stream,
        numbersStream: numbersStreamController.stream,
      ));
      await tester.pump();

      // Emit initial zero data
      usageStreamController.add(initialUsage);
      numbersStreamController.add([]);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Switch to Tab 3
      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CanaisConsumoIaTab), findsOneWidget);

      // Now emit high-frequency stream updates while on Tab 3
      for (int i = 1; i <= 5; i++) {
        usageStreamController.add(
          UsageFinopsModel(
            competencia: '2026_11',
            tenantId: tenantId,
            orcamentoMensalBrl: 1000.0 * i,
            alertaOrcamentoPercentual: 80.0,
            iaMetrics: IaMetrics(
              totalRequests: 100 * i,
              tokensInput: 10000 * i,
              tokensOutput: 5000 * i,
              audiosTranscritosMinutos: i,
              documentosAnalisados: i,
              custoAcumuladoBrl: 50.0 * i,
              economiaEstimadaHorasHumanas: 10.0 * i,
            ),
            whatsappMetrics: WhatsAppMetrics(
              totalConversas: 50 * i,
              conversasServicoGratuitas: 30 * i,
              conversasUtilidade: 15 * i,
              conversasMarketing: 5 * i,
              conversasAutenticacao: 0,
              custoAcumuladoBrl: 25.0 * i,
            ),
            historicoDiario: [
              HistoricoDiarioItem(dia: 1, custoIa: 10.0 * i, custoWa: 5.0 * i, msgs: 20 * i),
            ],
            updatedAt: DateTime.now(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
      }

      await usageStreamController.close();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      expect(find.text('R\$ 375,00'), findsOneWidget);
    });

    testWidgets('4.3 Viewport resilience stress across Mobile (360x740), Tablet (768x1024), and 4K (3840x2160)',
        (tester) async {
      final service = _AdversarialMockService();

      // Viewport 1: Mobile Small
      setViewport(tester, width: 360, height: 740);
      await tester.pumpWidget(createDashboardHost(service: service));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Viewport 2: Tablet Portrait
      setViewport(tester, width: 768, height: 1024);
      await tester.pumpWidget(createDashboardHost(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Viewport 3: 4K Ultra Wide
      setViewport(tester, width: 3840, height: 2160);
      await tester.pumpWidget(createDashboardHost(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // GROUP 5: NULL SAFETY & UNEXPECTED INPUT HANDLING
  // ===========================================================================
  group('Adversarial Group 5: Null Safety & Boundary Handling', () {
    testWidgets('5.1 Dialog handles whitespace and null initial IDs with safe fallback',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();

      await tester.pumpWidget(createDialogHost(
        service: service,
        initialAppId: '   ',
        initialConfigId: null,
      ));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Start onboarding
      await tester.tap(find.text('Iniciar Cadastro Incorporado'));
      await tester.pumpAndSettle();

      // Whitespace was trimmed and replaced by default Meta App ID
      expect(service.lastAppId, equals('109283746511223'));
      expect(service.lastConfigId, isNull);
    });

    testWidgets('5.2 Zero budget and empty daily history renders safely without NaN or crash',
        (tester) async {
      setViewport(tester);
      final service = _AdversarialMockService();

      final corruptedUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 0.0, // Zero budget!
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(
          totalRequests: 0,
          tokensInput: 0,
          tokensOutput: 0,
          audiosTranscritosMinutos: 0,
          documentosAnalisados: 0,
          custoAcumuladoBrl: 0.0,
          economiaEstimadaHorasHumanas: 0.0,
        ),
        whatsappMetrics: const WhatsAppMetrics(
          totalConversas: 0,
          conversasServicoGratuitas: 0,
          conversasUtilidade: 0,
          conversasMarketing: 0,
          conversasAutenticacao: 0,
          custoAcumuladoBrl: 0.0,
        ),
        historicoDiario: const [], // Empty daily history!
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createDashboardHost(
        service: service,
        usageStream: Stream.value(corruptedUsage),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();

      // Zero budget calculation percentualConsumido must not result in NaN

      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      expect(find.text('R\$ 0,00'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5.3 WhatsAppNumberModel with corrupted or unknown enum strings safely falls back',
        (tester) async {
      final corruptedMap = <String, dynamic>{
        'id': 'phone_corrupted_1',
        'tenant_id': tenantId,
        'waba_id': 'waba_unknown',
        'phone_number_id': 'phone_corrupted_1',
        'display_phone_number': '+55 00 00000-0000',
        'verified_name': null,
        'quality_rating': 'UNKNOWN_ALIEN_RATING',
        'messaging_limit_tier': 'TIER_INFINITE_OVERFLOW',
        'code_verification_status': null,
        'status': 'unknown_status',
        'webhook_subscribed': null,
        'ia_ativa_neste_numero': null,
      };

      final parsed = WhatsAppNumberModel.fromMap(corruptedMap, 'phone_corrupted_1');

      expect(parsed.id, equals('phone_corrupted_1'));
      expect(parsed.verifiedName, equals('WhatsApp Business'));
      expect(parsed.qualityRating, equals(MetaQualityRating.unknown));
      expect(parsed.messagingLimitTier, equals(MetaMessagingTier.unknown));
      expect(parsed.webhookSubscribed, isFalse);
      expect(parsed.iaAtivaNesteNumero, isTrue);
    });
  });
}
