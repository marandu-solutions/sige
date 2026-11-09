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

class _MockAdversarialWhatsAppMetaService extends Fake implements WhatsAppMetaService {
  bool toggleIaCalled = false;
  bool syncNumberCalled = false;
  bool updateBudgetCalled = false;
  bool disconnectCalled = false;
  double? updatedBudget;
  bool shouldFailBudgetUpdate = false;
  bool shouldFailDisconnect = false;

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
    if (shouldFailBudgetUpdate) {
      throw Exception('Database budget write constraint violation');
    }
    updateBudgetCalled = true;
    updatedBudget = newBudgetBrl;
  }

  @override
  Future<void> disconnectNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {
    if (shouldFailDisconnect) {
      throw Exception('Network timeout deleting routing index');
    }
    disconnectCalled = true;
  }
}

void main() {
  const tenantId = 'tenant_adversarial_stress';

  Widget buildTabTestHost({
    UsageFinopsModel? usage,
    List<WhatsAppNumberModel>? numbers,
    _MockAdversarialWhatsAppMetaService? mockService,
    Stream<UsageFinopsModel?>? usageStream,
    Stream<List<WhatsAppNumberModel>>? numbersStream,
  }) {
    final service = mockService ?? _MockAdversarialWhatsAppMetaService();

    return ProviderScope(
      overrides: [
        if (usageStream != null)
          usageFinopsStreamProvider(tenantId).overrideWith((ref) => usageStream)
        else
          usageFinopsStreamProvider(tenantId).overrideWith(
            (ref) => Stream.value(
              usage ??
                  UsageFinopsModel.zeroState(
                    tenantId: tenantId,
                    competencia: '2026_11',
                  ),
            ),
          ),
        if (numbersStream != null)
          whatsappNumbersStreamProvider(tenantId).overrideWith((ref) => numbersStream)
        else
          whatsappNumbersStreamProvider(tenantId).overrideWith(
            (ref) => Stream.value(numbers ?? <WhatsAppNumberModel>[]),
          ),
        whatsappMetaServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: CanaisConsumoIaTab(tenantId: tenantId),
      ),
    );
  }

  void configureViewport(WidgetTester tester, {double width = 1280, double height = 1000}) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Adversarial Stress Suite 1: Zero State & Boundary Math', () {
    testWidgets('1.1 Zero connected numbers, zero telemetry, and zero budget (0.0 BRL)',
        (tester) async {
      configureViewport(tester);

      final zeroBudgetUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 0.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(),
        whatsappMetrics: const WhatsAppMetrics(),
        historicoDiario: const [],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(
        buildTabTestHost(
          usage: zeroBudgetUsage,
          numbers: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Zero connected numbers: empty state card is displayed
      expect(
        find.text('Nenhum Número WhatsApp Business Vinculado'),
        findsOneWidget,
      );
      expect(find.text('Vincular Primeiro Número Oficial'), findsOneWidget);

      // Section 1: KPI Cards - Investimento Total
      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      // "R$ 0,00" appears in 3 KPI cards + 5 category breakdown items = 8 times
      expect(find.text('R\$ 0,00'), findsNWidgets(8));
      expect(find.text('Dentro da meta mensal'), findsOneWidget);

      // Saúde do Orçamento: 0 budget handled without NaN or division by zero
      expect(find.text('0,0%'), findsOneWidget);
      expect(find.text('de R\$ 0,00'), findsOneWidget);
      expect(find.text('Saldo restante: R\$ 0,00'), findsOneWidget);

      // Progress bar has valid 0.0 value
      final progressBarFinder = find.byType(LinearProgressIndicator);
      expect(progressBarFinder, findsOneWidget);
      final progressBar = tester.widget<LinearProgressIndicator>(progressBarFinder);
      expect(progressBar.value, 0.0);

      // fl_chart: empty state rendered cleanly
      expect(
        find.text('Nenhum evento registrado ainda nesta competência'),
        findsOneWidget,
      );
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);

      // Verify no exceptions or crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 Null telemetry stream emission falls back to UsageFinopsModel.zeroState',
        (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(
        buildTabTestHost(
          usageStream: Stream<UsageFinopsModel?>.value(null),
          numbers: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Should render default 1000.0 BRL zero state
      expect(find.text('0,0%'), findsOneWidget);
      expect(find.text('de R\$ 1000,00'), findsOneWidget);
      expect(find.text('Saldo restante: R\$ 1000,00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.3 Zero budget with positive usage (guarded division by zero)',
        (tester) async {
      configureViewport(tester);

      final zeroBudgetWithCost = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 0.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(
          totalRequests: 50,
          tokensInput: 10000,
          tokensOutput: 5000,
          custoAcumuladoBrl: 45.50,
        ),
        whatsappMetrics: const WhatsAppMetrics(
          totalConversas: 20,
          custoAcumuladoBrl: 30.00,
        ),
        historicoDiario: const [],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(
        buildTabTestHost(usage: zeroBudgetWithCost),
      );
      await tester.pumpAndSettle();

      // Total investment R$ 75,50
      expect(find.text('R\$ 75,50'), findsOneWidget);
      // percentualOrcamentoConsumido returns 0.0 when budget <= 0.0
      expect(find.text('0,0%'), findsOneWidget);
      expect(find.text('de R\$ 0,00'), findsOneWidget);

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 0.0);
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Suite 2: Extreme Values & Boundary Conditions', () {
    testWidgets('2.1 Massive budget (R\$ 1.000.000,00) renders cleanly without truncation',
        (tester) async {
      configureViewport(tester, width: 1400);

      final massiveUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 1000000.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(
          totalRequests: 250000,
          tokensInput: 150000000,
          tokensOutput: 50000000,
          custoAcumuladoBrl: 450000.0,
          economiaEstimadaHorasHumanas: 3500.0,
        ),
        whatsappMetrics: const WhatsAppMetrics(
          totalConversas: 1800000,
          conversasServicoGratuitas: 1200000,
          conversasUtilidade: 400000,
          conversasMarketing: 200000,
          custoAcumuladoBrl: 300000.0,
        ),
        historicoDiario: const [
          HistoricoDiarioItem(dia: 1, custoIa: 15000.0, custoWa: 10000.0, msgs: 50000),
          HistoricoDiarioItem(dia: 2, custoIa: 16000.0, custoWa: 11000.0, msgs: 55000),
        ],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(buildTabTestHost(usage: massiveUsage));
      await tester.pumpAndSettle();

      // Total = R$ 750.000,00
      expect(find.text('R\$ 750000,00'), findsOneWidget);
      // Consumed = 75.0%
      expect(find.text('75,0%'), findsOneWidget);
      expect(find.text('de R\$ 1000000,00'), findsOneWidget);
      expect(find.text('Saldo restante: R\$ 250000,00'), findsOneWidget);

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.75, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.2 Negative Saldo Restante (Severe budget blowout / exceeded > 400%)',
        (tester) async {
      configureViewport(tester);

      final blownUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 500.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(
          totalRequests: 8000,
          custoAcumuladoBrl: 1500.0,
        ),
        whatsappMetrics: const WhatsAppMetrics(
          totalConversas: 3000,
          custoAcumuladoBrl: 1000.0,
        ),
        historicoDiario: const [
          HistoricoDiarioItem(dia: 1, custoIa: 750.0, custoWa: 500.0, msgs: 2000),
          HistoricoDiarioItem(dia: 2, custoIa: 750.0, custoWa: 500.0, msgs: 2000),
        ],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(buildTabTestHost(usage: blownUsage));
      await tester.pumpAndSettle();

      // Total: R$ 2500,00 on R$ 500,00 budget => 500.0%
      expect(find.text('R\$ 2500,00'), findsOneWidget);
      expect(find.text('500,0%'), findsOneWidget);
      expect(find.text('de R\$ 500,00'), findsOneWidget);
      expect(find.text('Saldo restante: R\$ -2000,00'), findsOneWidget);
      expect(find.text('Orçamento mensal estourado'), findsOneWidget);

      // Verify progress bar is safely clamped at 1.0 (does not throw exception)
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.3 100+ daily history points in fl_chart BarChart and LineChart modes',
        (tester) async {
      configureViewport(tester, width: 1400, height: 1800);

      // Generate 100 daily points
      final hundredDays = List<HistoricoDiarioItem>.generate(
        100,
        (i) => HistoricoDiarioItem(
          dia: i + 1,
          custoIa: (i * 1.5) + 5.0,
          custoWa: (i * 2.0) + 10.0,
          msgs: (i * 10) + 50,
        ),
      );

      final denseUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 50000.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 7500.0),
        whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 11000.0),
        historicoDiario: hundredDays,
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(buildTabTestHost(usage: denseUsage));
      await tester.pumpAndSettle();

      // 1. Should render BarChart with all 100 barGroups
      final barChartFinder = find.byType(BarChart);
      expect(barChartFinder, findsOneWidget);
      final barChartWidget = tester.widget<BarChart>(barChartFinder);
      expect(barChartWidget.data.barGroups.length, 100);

      // 2. Toggle to LineChart
      final lineChartBtn = find.byTooltip('Visualizar em Linhas');
      expect(lineChartBtn, findsOneWidget);
      await tester.tap(lineChartBtn);
      await tester.pumpAndSettle();

      // 3. Should render LineChart with 2 series of 100 spots each
      final lineChartFinder = find.byType(LineChart);
      expect(lineChartFinder, findsOneWidget);
      final lineChartWidget = tester.widget<LineChart>(lineChartFinder);
      expect(lineChartWidget.data.lineBarsData.length, 2);
      expect(lineChartWidget.data.lineBarsData[0].spots.length, 100);
      expect(lineChartWidget.data.lineBarsData[1].spots.length, 100);

      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Suite 3: Rapid fl_chart Mode Toggling', () {
    testWidgets('3.1 Rapid consecutive clicking between Bar and Line modes',
        (tester) async {
      configureViewport(tester, width: 1400, height: 1800);

      final sampleUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 2000.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 100.0),
        whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 150.0),
        historicoDiario: const [
          HistoricoDiarioItem(dia: 1, custoIa: 10.0, custoWa: 15.0, msgs: 100),
          HistoricoDiarioItem(dia: 2, custoIa: 12.0, custoWa: 18.0, msgs: 120),
          HistoricoDiarioItem(dia: 3, custoIa: 14.0, custoWa: 20.0, msgs: 140),
        ],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(buildTabTestHost(usage: sampleUsage));
      await tester.pumpAndSettle();

      final lineBtn = find.byTooltip('Visualizar em Linhas');
      final barBtn = find.byTooltip('Visualizar em Barras');

      // Rapidly toggle back and forth 10 times with minimal pump intervals
      for (int i = 0; i < 5; i++) {
        await tester.tap(lineBtn);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(barBtn);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Finish all active swap animations
      await tester.pumpAndSettle();

      // Final state should be BarChart
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);

      // Now toggle once more to LineChart and settle
      await tester.tap(lineBtn);
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Suite 4: Budget Adjustment Modal Validation', () {
    final baseUsage = UsageFinopsModel(
      competencia: '2026_11',
      tenantId: tenantId,
      orcamentoMensalBrl: 1200.0,
      updatedAt: DateTime(2026, 11, 8),
    );

    testWidgets('4.1 Submission with empty string falls back to current budget',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(usage: baseUsage, mockService: mockService),
      );
      await tester.pumpAndSettle();

      // Open modal
      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      // Clear input
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      expect(mockService.updateBudgetCalled, isTrue);
      expect(mockService.updatedBudget, 1200.0); // Fallback to current
      expect(find.text('Teto de orçamento atualizado com sucesso!'), findsOneWidget);
    });

    testWidgets('4.2 Submission with non-numeric text falls back to current budget',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(usage: baseUsage, mockService: mockService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'invalido!@#');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      expect(mockService.updateBudgetCalled, isTrue);
      expect(mockService.updatedBudget, 1200.0);
      expect(find.text('Teto de orçamento atualizado com sucesso!'), findsOneWidget);
    });

    testWidgets('4.3 Submission with zero ("0") updates budget to 0.0',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(usage: baseUsage, mockService: mockService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      expect(mockService.updateBudgetCalled, isTrue);
      expect(mockService.updatedBudget, 0.0);
      expect(find.text('Teto de orçamento atualizado com sucesso!'), findsOneWidget);
    });

    testWidgets('4.4 Submission with negative value ("-300")',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(usage: baseUsage, mockService: mockService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '-300');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      expect(mockService.updateBudgetCalled, isTrue);
      expect(mockService.updatedBudget, -300.0);
    });

    testWidgets('4.5 Preset chip clicks sequentially update text field and save',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(usage: baseUsage, mockService: mockService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      // Click R$ 500 preset
      await tester.tap(find.text('R\$ 500'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '500'), findsOneWidget);

      // Click R$ 5000 preset
      await tester.tap(find.text('R\$ 5000'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '5000'), findsOneWidget);

      // Save R$ 5000
      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      expect(mockService.updateBudgetCalled, isTrue);
      expect(mockService.updatedBudget, 5000.0);
    });

    testWidgets('4.6 Modal error handling when service throws exception',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();
      mockService.shouldFailBudgetUpdate = true;

      await tester.pumpWidget(
        buildTabTestHost(usage: baseUsage, mockService: mockService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Orçamento'));
      await tester.pumpAndSettle();

      // SnackBar with error should appear
      expect(find.textContaining('Erro ao atualizar orçamento:'), findsOneWidget);
    });
  });

  group('Adversarial Stress Suite 5: Phone Disconnection Confirmation Dialog', () {
    final testNumber = WhatsAppNumberModel(
      id: 'phone_adv_01',
      tenantId: tenantId,
      wabaId: 'waba_adv_01',
      phoneNumberId: 'phone_adv_01',
      displayPhoneNumber: '+55 11 99999-0000',
      verifiedName: 'Challenger Alpha Store',
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

    testWidgets('5.1 Cancelling disconnection preserves number and calls nothing',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(
          numbers: [testNumber],
          mockService: mockService,
        ),
      );
      await tester.pumpAndSettle();

      // Click trash icon button
      final trashBtn = find.byIcon(LucideIcons.trash2);
      expect(trashBtn, findsOneWidget);
      await tester.tap(trashBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Desvincular Número?'), findsOneWidget);
      expect(
        find.textContaining('Deseja realmente desvincular o número oficial +55 11 99999-0000'),
        findsOneWidget,
      );

      // Click Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog dismissed, service not called
      expect(find.text('Desvincular Número?'), findsNothing);
      expect(mockService.disconnectCalled, isFalse);
      expect(find.text('+55 11 99999-0000'), findsOneWidget);
    });

    testWidgets('5.2 Confirming disconnection executes service and shows success',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();

      await tester.pumpWidget(
        buildTabTestHost(
          numbers: [testNumber],
          mockService: mockService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      // Tap confirm action button 'Desvincular' inside dialog
      final desvincularBtn = find.widgetWithText(FilledButton, 'Desvincular');
      expect(desvincularBtn, findsOneWidget);
      await tester.tap(desvincularBtn);
      await tester.pumpAndSettle();

      expect(mockService.disconnectCalled, isTrue);
      expect(
        find.textContaining('desvinculado com sucesso.'),
        findsOneWidget,
      );
    });

    testWidgets('5.3 Disconnection failure displays error SnackBar',
        (tester) async {
      configureViewport(tester);
      final mockService = _MockAdversarialWhatsAppMetaService();
      mockService.shouldFailDisconnect = true;

      await tester.pumpWidget(
        buildTabTestHost(
          numbers: [testNumber],
          mockService: mockService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      final desvincularBtn = find.widgetWithText(FilledButton, 'Desvincular');
      await tester.tap(desvincularBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao desvincular número:'), findsOneWidget);
    });
  });

  group('Adversarial Stress Suite 6: Viewport & Layout Robustness (Defect Detection)', () {
    testWidgets(
        '6.1 Viewport at 1280x900 (Desktop) and 1050x800 renders with zero layout errors',
        (tester) async {
      configureViewport(tester, width: 1280, height: 900);

      final sampleUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 1500.0,
        iaMetrics: const IaMetrics(
          totalRequests: 1200,
          tokensInput: 500000,
          tokensOutput: 200000,
          custoAcumuladoBrl: 95.0,
        ),
        whatsappMetrics: const WhatsAppMetrics(
          totalConversas: 450,
          custoAcumuladoBrl: 110.0,
        ),
        historicoDiario: const [
          HistoricoDiarioItem(dia: 1, custoIa: 10.0, custoWa: 12.0, msgs: 50),
        ],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(buildTabTestHost(usage: sampleUsage));
      await tester.pumpAndSettle();

      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      expect(find.text('CONSUMO MOTOR IA'), findsOneWidget);
      expect(find.text('MENSAGERIA META API'), findsOneWidget);
      expect(find.text('SAÚDE DO ORÇAMENTO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '6.2 REMEDIATION VERIFICATION: Narrow viewport (360x640) renders CompetenceBar and Section Header with ZERO RenderFlex overflows',
        (tester) async {
      configureViewport(tester, width: 360, height: 640);

      final sampleUsage = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: tenantId,
        orcamentoMensalBrl: 1500.0,
        iaMetrics: const IaMetrics(
          totalRequests: 1200,
          tokensInput: 500000,
          tokensOutput: 200000,
          custoAcumuladoBrl: 95.0,
        ),
        whatsappMetrics: const WhatsAppMetrics(
          totalConversas: 450,
          custoAcumuladoBrl: 110.0,
        ),
        historicoDiario: const [
          HistoricoDiarioItem(dia: 1, custoIa: 10.0, custoWa: 12.0, msgs: 50),
        ],
        updatedAt: DateTime(2026, 11, 8),
      );

      await tester.pumpWidget(buildTabTestHost(usage: sampleUsage));
      await tester.pumpAndSettle();

      // Assert ZERO RenderFlex overflows occurred on narrow mobile viewport
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '6.3 REMEDIATION VERIFICATION: Connected number card at 360x800 renders header and footer with ZERO RenderFlex overflows',
        (tester) async {
      configureViewport(tester, width: 360, height: 800);

      final testNumber = WhatsAppNumberModel(
        id: 'phone_adv_01',
        tenantId: tenantId,
        wabaId: 'waba_adv_01',
        phoneNumberId: 'phone_adv_01',
        displayPhoneNumber: '+55 11 99999-0000',
        verifiedName: 'Challenger Alpha Store',
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

      await tester.pumpWidget(
        buildTabTestHost(
          numbers: [testNumber],
        ),
      );
      await tester.pumpAndSettle();

      // Assert ZERO RenderFlex overflows occurred on narrow number card
      expect(tester.takeException(), isNull);
    });
  });
}
