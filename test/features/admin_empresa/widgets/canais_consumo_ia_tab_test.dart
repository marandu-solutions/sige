import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sige/src/features/admin_empresa/src/models/usage_finops_model.dart';
import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/whatsapp_finops_providers.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/canais_consumo_ia_tab.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

class _MockWhatsAppMetaService extends Fake implements WhatsAppMetaService {
  bool toggleIaCalled = false;
  bool syncNumberCalled = false;
  bool updateBudgetCalled = false;
  bool disconnectCalled = false;
  double? updatedBudget;

  @override
  Future<void> toggleIa({
    required String tenantId,
    required String phoneNumberId,
    required bool enabled,
  }) async {
    toggleIaCalled = true;
  }

  @override
  Future<void> syncNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {
    syncNumberCalled = true;
  }

  @override
  Future<void> updateMonthlyBudget({
    required String tenantId,
    required double newBudgetBrl,
    String? competencia,
  }) async {
    updateBudgetCalled = true;
    updatedBudget = newBudgetBrl;
  }

  @override
  Future<void> disconnectNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {
    disconnectCalled = true;
  }
}

void main() {
  const tenantId = 'tenant_test_tab';

  final sampleUsage = UsageFinopsModel(
    competencia: '2026_11',
    tenantId: tenantId,
    orcamentoMensalBrl: 1500.0,
    alertaOrcamentoPercentual: 80.0,
    iaMetrics: const IaMetrics(
      totalRequests: 4280,
      tokensInput: 1850400,
      tokensOutput: 620100,
      audiosTranscritosMinutos: 45,
      documentosAnalisados: 120,
      custoAcumuladoBrl: 214.60,
      economiaEstimadaHorasHumanas: 118.5,
    ),
    whatsappMetrics: const WhatsAppMetrics(
      totalConversas: 1940,
      conversasServicoGratuitas: 1420,
      conversasUtilidade: 380,
      conversasMarketing: 110,
      conversasAutenticacao: 30,
      custoAcumuladoBrl: 348.20,
    ),
    historicoDiario: const [
      HistoricoDiarioItem(dia: 1, custoIa: 18.40, custoWa: 29.10, msgs: 160),
      HistoricoDiarioItem(dia: 2, custoIa: 22.10, custoWa: 35.40, msgs: 195),
      HistoricoDiarioItem(dia: 3, custoIa: 25.80, custoWa: 41.20, msgs: 230),
    ],
    updatedAt: DateTime(2026, 11, 8, 15, 0),
  );

  final sampleNumbers = [
    WhatsAppNumberModel(
      id: 'phone_01',
      tenantId: tenantId,
      wabaId: 'waba_meta_01',
      phoneNumberId: 'phone_01',
      displayPhoneNumber: '+55 11 98877-6655',
      verifiedName: 'EPI Forte Comercial',
      qualityRating: MetaQualityRating.green,
      messagingLimitTier: MetaMessagingTier.tier10k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      iaAtivaNesteNumero: true,
      isDefault: true,
      connectedAt: DateTime(2026, 11, 1),
      lastSyncAt: DateTime(2026, 11, 8),
    ),
  ];

  Widget createTabHost({
    UsageFinopsModel? usage,
    List<WhatsAppNumberModel>? numbers,
    _MockWhatsAppMetaService? mockService,
  }) {
    final service = mockService ?? _MockWhatsAppMetaService();

    return ProviderScope(
      overrides: [
        usageFinopsStreamProvider(tenantId)
            .overrideWith((ref) => Stream.value(usage ?? sampleUsage)),
        whatsappNumbersStreamProvider(tenantId)
            .overrideWith((ref) => Stream.value(numbers ?? sampleNumbers)),
        whatsappMetaServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: CanaisConsumoIaTab(tenantId: tenantId),
      ),
    );
  }

  group('CanaisConsumoIaTab Widget Tests', () {
    void setDesktopSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('1. Renders Competence Bar with dropdown', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createTabHost());
      await tester.pumpAndSettle();

      expect(find.text('Competência Contábil FinOps'), findsOneWidget);
      expect(find.textContaining('Telemetria Mensal Agregada'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('2. Section 1 renders 4 Executive KPI cards with accurate metrics',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createTabHost());
      await tester.pumpAndSettle();

      // Card 1: Investimento Total
      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      expect(find.text('R\$ 562,80'), findsOneWidget);
      expect(find.textContaining('Dentro da meta mensal'), findsOneWidget);

      // Card 2: Consumo Motor IA (appears in KPI card and category breakdown)
      expect(find.text('CONSUMO MOTOR IA'), findsOneWidget);
      expect(find.text('R\$ 214,60'), findsNWidgets(2));
      expect(find.textContaining('tokens consumidos'), findsOneWidget);
      expect(find.textContaining('4280 respostas automáticas'), findsOneWidget);

      // Card 3: Mensageria Meta API
      expect(find.text('MENSAGERIA META API'), findsOneWidget);
      expect(find.text('R\$ 348,20'), findsOneWidget);
      expect(find.textContaining('1940 conversas no período'), findsOneWidget);
      expect(find.textContaining('1420 janelas grátis 24h'), findsOneWidget);

      // Card 4: Saúde do Orçamento
      expect(find.text('SAÚDE DO ORÇAMENTO'), findsOneWidget);
      expect(find.text('37,5%'), findsOneWidget);
      expect(find.textContaining('1500,00'), findsOneWidget);
      expect(find.text('Saldo restante: R\$ 937,20'), findsOneWidget);
      expect(find.text('Ajustar'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('3. Section 2 renders Connected Numbers grid with badges and IA switch',
        (tester) async {
      setDesktopSize(tester);
      final mockService = _MockWhatsAppMetaService();
      await tester.pumpWidget(createTabHost(mockService: mockService));
      await tester.pumpAndSettle();

      expect(
        find.text('Central de Números WhatsApp Business Oficiais (Meta Cloud API)'),
        findsOneWidget,
      );
      expect(find.text('Conectar WhatsApp Oficial'), findsOneWidget);

      // Number card
      expect(find.text('+55 11 98877-6655'), findsOneWidget);
      expect(find.text('EPI Forte Comercial'), findsOneWidget);
      expect(find.text('OFICIAL META ✓'), findsOneWidget);
      expect(find.text('PADRÃO'), findsOneWidget);
      expect(find.text('🟢 ALTA (GREEN)'), findsOneWidget);
      expect(find.text('10.000 conversas/24h (TIER_10K)'), findsOneWidget);
      expect(find.text('🟢 Inscrito (subscribed_apps ativo)'), findsOneWidget);

      // 24/7 IA Switch
      expect(find.text('IA 24/7:'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Actions
      expect(find.text('Sincronizar'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);

      // Test Sincronizar tap
      await tester.tap(find.text('Sincronizar'));
      await tester.pumpAndSettle();
      expect(mockService.syncNumberCalled, isTrue);

      // Test toggle IA switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(mockService.toggleIaCalled, isTrue);
    });

    testWidgets('4. Section 2 displays Zero State when numbers list is empty',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createTabHost(numbers: const []));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum Número WhatsApp Business Vinculado'),
        findsOneWidget,
      );
      expect(
        find.text('Vincular Primeiro Número Oficial'),
        findsOneWidget,
      );
    });

    testWidgets('5. Section 3 renders Daily Evolution Chart and Category Breakdown',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createTabHost());
      await tester.pumpAndSettle();

      // Chart Title & Legend
      expect(find.text('Evolução Diária de Custos'), findsOneWidget);
      expect(find.text('Custo IA'), findsOneWidget);
      expect(find.text('Custo Meta'), findsOneWidget);

      // BarChart initially rendered
      expect(find.byType(BarChart), findsOneWidget);

      // Switch to LineChart mode
      await tester.tap(find.byIcon(LucideIcons.chartLine));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);

      // Switch back to BarChart mode
      await tester.tap(find.byIcon(LucideIcons.chartColumn));
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);

      // Category Breakdown List
      expect(find.text('Detalhamento por Categoria'), findsOneWidget);
      expect(find.text('Janelas de Serviço (Grátis 24h)'), findsOneWidget);
      expect(find.text('GRÁTIS'), findsOneWidget);
      expect(find.text('Templates de Utilidade'), findsOneWidget);
      expect(find.text('Templates de Marketing'), findsOneWidget);
      expect(find.text('Motor de IA LLM (Texto/Cotações)'), findsOneWidget);
      expect(find.text('Multimodal (Áudio STT & Visão)'), findsOneWidget);

      // Human hours saved banner
      expect(
        find.textContaining('118.5 horas de equipe humana poupadas'),
        findsOneWidget,
      );
    });

    testWidgets('6. Adjust Budget Modal allows selecting presets and saving new budget',
        (tester) async {
      setDesktopSize(tester);
      final mockService = _MockWhatsAppMetaService();
      await tester.pumpWidget(createTabHost(mockService: mockService));
      await tester.pumpAndSettle();

      // Open Adjust Budget modal
      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      expect(find.text('Ajustar Teto de Orçamento'), findsOneWidget);
      expect(find.text('R\$ 2500'), findsOneWidget);

      // Tap preset 2500
      await tester.tap(find.text('R\$ 2500'));
      await tester.pumpAndSettle();

      // Save budget
      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      expect(mockService.updateBudgetCalled, isTrue);
      expect(mockService.updatedBudget, equals(2500.0));
    });

    testWidgets('7. Disconnect number confirmation dialog handles cancel and confirm',
        (tester) async {
      setDesktopSize(tester);
      final mockService = _MockWhatsAppMetaService();
      await tester.pumpWidget(createTabHost(mockService: mockService));
      await tester.pumpAndSettle();

      // Open Disconnect confirmation
      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      expect(find.text('Desvincular Número?'), findsOneWidget);
      expect(
        find.textContaining('Deseja realmente desvincular o número oficial'),
        findsOneWidget,
      );

      // Tap Desvincular confirm button
      await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
      await tester.pumpAndSettle();

      expect(mockService.disconnectCalled, isTrue);
    });
  });
}
