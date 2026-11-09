import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/whatsapp_finops_providers.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/whatsapp_embedded_signup_dialog.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_models.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

class _FakeWhatsAppMetaService extends Fake implements WhatsAppMetaService {}

class _TestEmbeddedSignupController extends EmbeddedSignupController {
  _TestEmbeddedSignupController(EmbeddedSignupState initialState)
      : super(_FakeWhatsAppMetaService()) {
    state = initialState;
  }

  void setStateForTest(EmbeddedSignupState newState) {
    state = newState;
  }
}

void main() {
  const tenantId = 'tenant_test_123';

  final sampleCompletedNumber = WhatsAppNumberModel(
    id: 'phone_num_999',
    tenantId: tenantId,
    wabaId: 'waba_1122334455',
    phoneNumberId: 'phone_num_999',
    displayPhoneNumber: '+55 11 99988-7766',
    verifiedName: 'Empresa Teste Brasil',
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
    EmbeddedSignupState state = const EmbeddedSignupState(),
    _TestEmbeddedSignupController? customController,
    ValueChanged<WhatsAppNumberModel>? onCompleted,
    bool defaultSimulationMode = false,
  }) {
    final controller = customController ?? _TestEmbeddedSignupController(state);

    return ProviderScope(
      overrides: [
        embeddedSignupControllerProvider.overrideWith((ref) => controller),
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
                    defaultSimulationMode: defaultSimulationMode,
                    onCompleted: onCompleted,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('WhatsAppEmbeddedSignupDialog Widget Tests', () {
    void setDesktopSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('1. Renders idle state with all 4 stepper headers, permissions and CTA',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createDialogHost());

      // Open dialog
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Conectar WhatsApp Oficial'), findsOneWidget);
      expect(find.text('Meta v21.0'), findsOneWidget);

      // 4 Stepper stage titles in the stepper header
      expect(find.text('Meta Login'), findsOneWidget);
      expect(find.text('Identificadores'), findsOneWidget);
      expect(find.text('Webhooks'), findsOneWidget);
      expect(find.text('Operacional'), findsOneWidget);

      // Permissions checklist
      expect(find.text('Permissões Oficiais Requeridas'), findsOneWidget);
      expect(
        find.textContaining('whatsapp_business_management'),
        findsOneWidget,
      );
      expect(
        find.textContaining('whatsapp_business_messaging'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Webhooks Automáticos'),
        findsOneWidget,
      );

      // Simulation mode card
      expect(find.text('Modo Homologação / Simulação'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Action button
      expect(find.text('Iniciar Cadastro Incorporado'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('2. Toggling Advanced Settings expands Meta App ID & Config ID fields',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createDialogHost());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Meta Tech Provider App ID'), findsNothing);

      // Tap on collapsible settings
      await tester.tap(find.text('Configurações Avançadas da Meta API (Opcional)'));
      await tester.pumpAndSettle();

      expect(find.text('Meta Tech Provider App ID'), findsOneWidget);
      expect(find.text('Facebook Login Configuration ID (Opcional)'), findsOneWidget);
    });

    testWidgets('3. Renders processing stage 1 (authenticatingInMeta) with spinner',
        (tester) async {
      setDesktopSize(tester);
      const state = EmbeddedSignupState(
        step: MetaSignupStep.authenticatingInMeta,
        isBusy: true,
      );

      await tester.pumpWidget(createDialogHost(state: state));

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Autenticando com a Meta...'), findsOneWidget);
      expect(
        find.textContaining('Uma janela pop-up oficial do Facebook foi aberta'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // In busy state, cancel button is hidden in footer
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('4. Renders processing stage 2 (capturingSessionIds)', (tester) async {
      setDesktopSize(tester);
      const state = EmbeddedSignupState(
        step: MetaSignupStep.capturingSessionIds,
        isBusy: true,
      );

      await tester.pumpWidget(createDialogHost(state: state));

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Capturando identificadores oficiais...'), findsOneWidget);
      expect(
        find.textContaining('Evento seguro WA_EMBEDDED_SIGNUP recebido'),
        findsOneWidget,
      );
    });

    testWidgets('5. Renders processing stage 3 (exchangingTokenAndSubscribing)',
        (tester) async {
      setDesktopSize(tester);
      const state = EmbeddedSignupState(
        step: MetaSignupStep.exchangingTokenAndSubscribing,
        isBusy: true,
      );

      await tester.pumpWidget(createDialogHost(state: state));

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Trocando credenciais e ativando webhooks...'),
        findsOneWidget,
      );
      expect(
        find.textContaining('A Cloud Function do SIGE está trocando o token definitivo'),
        findsOneWidget,
      );
    });

    testWidgets('6. Cancelled state renders alert card and resets on "Tentar Novamente"',
        (tester) async {
      setDesktopSize(tester);
      final controller = _TestEmbeddedSignupController(
        const EmbeddedSignupState(
          step: MetaSignupStep.cancelled,
          errorMessage: 'Pop-up fechado pelo usuário.',
        ),
      );

      await tester.pumpWidget(createDialogHost(
        customController: controller,
        defaultSimulationMode: false,
      ));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Conexão Cancelada pelo Usuário'), findsOneWidget);
      expect(find.text('Pop-up fechado pelo usuário.'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);

      // Tap Tentar Novamente
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();

      // State is reset to idle
      expect(controller.state.step, equals(MetaSignupStep.idle));
    });

    testWidgets('7. Error state renders failure card, error message, and options',
        (tester) async {
      setDesktopSize(tester);
      final controller = _TestEmbeddedSignupController(
        const EmbeddedSignupState(
          step: MetaSignupStep.error,
          errorMessage: 'Credenciais inválidas da Meta.',
        ),
      );

      await tester.pumpWidget(createDialogHost(
        customController: controller,
        defaultSimulationMode: false,
      ));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Falha na Conexão com a Meta'), findsOneWidget);
      expect(find.text('Credenciais inválidas da Meta.'), findsOneWidget);
      expect(find.text('Modo Simulação'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
    });

    testWidgets('8. Completed stage renders connected number card, badges and invokes onCompleted',
        (tester) async {
      setDesktopSize(tester);
      WhatsAppNumberModel? completedResult;

      final state = EmbeddedSignupState(
        step: MetaSignupStep.completed,
        connectedNumber: sampleCompletedNumber,
      );

      await tester.pumpWidget(createDialogHost(
        state: state,
        onCompleted: (number) {
          completedResult = number;
        },
      ));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Success celebration banner
      expect(find.text('Número Oficial Conectado com Sucesso!'), findsOneWidget);

      // Connected card details
      expect(find.text('+55 11 99988-7766'), findsOneWidget);
      expect(find.text('Empresa Teste Brasil'), findsOneWidget);
      expect(find.text('OFICIAL META ✓'), findsOneWidget);

      // Badges
      expect(find.text('🟢 ALTA (GREEN)'), findsOneWidget);
      expect(find.text('🚀 10.000/dia'), findsOneWidget);
      expect(find.text('🟢 Webhook Ativo'), findsOneWidget);
      expect(find.text('🤖 IA 24/7 Ativa'), findsOneWidget);

      // Identifiers
      expect(find.textContaining('waba_1122334455'), findsOneWidget);
      expect(find.textContaining('phone_num_999'), findsOneWidget);

      // Action button
      final finishBtn = find.text('Concluir & Ir ao Painel');
      expect(finishBtn, findsOneWidget);

      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      expect(completedResult, isNotNull);
      expect(completedResult?.phoneNumberId, equals('phone_num_999'));
      expect(completedResult?.displayPhoneNumber, equals('+55 11 99988-7766'));
    });
  });
}
