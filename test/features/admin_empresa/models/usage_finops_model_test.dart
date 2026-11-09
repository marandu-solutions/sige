import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/models/usage_finops_model.dart';

void main() {
  group('IaMetrics Unit Tests', () {
    test('Default values and calculations', () {
      const metrics = IaMetrics();
      expect(metrics.totalRequests, equals(0));
      expect(metrics.totalTokens, equals(0));
      expect(metrics.custoMedioPorRequest, equals(0.0));
      expect(metrics.totalTokensFormatado, equals('0'));
      expect(metrics.custoFormatadoBrl, equals('R\$ 0,00'));
    });

    test('Formatted tokens string for large values (k, M)', () {
      const kMetrics = IaMetrics(tokensInput: 15400, tokensOutput: 3100);
      expect(kMetrics.totalTokensFormatado, equals('18,5k'));

      const mMetrics = IaMetrics(tokensInput: 1850400, tokensOutput: 620100);
      expect(mMetrics.totalTokensFormatado, equals('2,47M'));
    });

    test('fromMap and toMap round-trip', () {
      final map = {
        'total_requests': 100,
        'tokens_input': 50000,
        'tokens_output': 10000,
        'audios_transcritos_minutos': 30,
        'documentos_analisados': 12,
        'custo_acumulado_brl': 45.50,
        'economia_estimada_horas_humanas': 25.0,
      };

      final metrics = IaMetrics.fromMap(map);
      expect(metrics.totalRequests, equals(100));
      expect(metrics.totalTokens, equals(60000));
      expect(metrics.custoAcumuladoBrl, equals(45.50));

      final serialized = metrics.toMap();
      expect(serialized['total_requests'], equals(100));
      expect(serialized['custo_acumulado_brl'], equals(45.50));
    });

    test('copyWith and value equality', () {
      const m1 = IaMetrics(totalRequests: 10, custoAcumuladoBrl: 5.0);
      final m2 = m1.copyWith(totalRequests: 20);
      expect(m2.totalRequests, equals(20));
      expect(m2.custoAcumuladoBrl, equals(5.0));

      final m1Clone = m1.copyWith();
      expect(m1Clone, equals(m1));
      expect(m1Clone.hashCode, equals(m1.hashCode));
    });
  });

  group('WhatsAppMetrics Unit Tests', () {
    test('Default values and calculations', () {
      const wa = WhatsAppMetrics();
      expect(wa.totalConversas, equals(0));
      expect(wa.conversasPagas, equals(0));
      expect(wa.percentualGratuitas, equals(0.0));
      expect(wa.custoFormatadoBrl, equals('R\$ 0,00'));
    });

    test('conversasPagas and percentualGratuitas calculations', () {
      const wa = WhatsAppMetrics(
        totalConversas: 1000,
        conversasServicoGratuitas: 800,
        conversasUtilidade: 100,
        conversasMarketing: 80,
        conversasAutenticacao: 20,
        custoAcumuladoBrl: 150.0,
      );

      expect(wa.conversasPagas, equals(200));
      expect(wa.percentualGratuitas, equals(80.0));
      expect(wa.custoFormatadoBrl, equals('R\$ 150,00'));
    });

    test('fromMap and toMap serialization', () {
      final map = {
        'total_conversas': 500,
        'conversas_servico_gratuitas': 400,
        'conversas_utilidade': 50,
        'conversas_marketing': 40,
        'conversas_autenticacao': 10,
        'custo_acumulado_brl': 75.0,
      };

      final wa = WhatsAppMetrics.fromMap(map);
      expect(wa.totalConversas, equals(500));
      expect(wa.conversasPagas, equals(100));

      final serialized = wa.toMap();
      expect(serialized['total_conversas'], equals(500));
    });
  });

  group('HistoricoDiarioItem Unit Tests', () {
    test('Calculates total daily cost correctly', () {
      const item = HistoricoDiarioItem(
        dia: 5,
        custoIa: 15.20,
        custoWa: 24.80,
        msgs: 150,
      );

      expect(item.dia, equals(5));
      expect(item.custoTotal, equals(40.00));
      expect(item.custoTotalFormatado, equals('R\$ 40,00'));
    });

    test('Serialization toMap and fromMap', () {
      final map = {
        'dia': 12,
        'custo_ia': 10.5,
        'custo_wa': 20.5,
        'msgs': 300,
      };

      final item = HistoricoDiarioItem.fromMap(map);
      expect(item.dia, equals(12));
      expect(item.custoTotal, equals(31.0));

      final serialized = item.toMap();
      expect(serialized['msgs'], equals(300));
    });
  });

  group('FinopsHealthStatus Enum Tests', () {
    test('Labels and colors for all health statuses', () {
      for (final status in FinopsHealthStatus.values) {
        expect(status.label, isNotEmpty);
        expect(status.color, isA<Color>());
      }
    });
  });

  group('UsageFinopsModel Domain Tests', () {
    final now = DateTime(2026, 11, 8, 15, 0);

    test('zeroState factory provides clean non-null defaults with 0 spend', () {
      final zero = UsageFinopsModel.zeroState(
        tenantId: 'tenant_epi_01',
        competencia: '2026_11',
      );

      expect(zero.competencia, equals('2026_11'));
      expect(zero.tenantId, equals('tenant_epi_01'));
      expect(zero.orcamentoMensalBrl, equals(1000.0));
      expect(zero.custoTotalAcumuladoBrl, equals(0.0));
      expect(zero.percentualOrcamentoConsumido, equals(0.0));
      expect(zero.saldoOrcamentoBrl, equals(1000.0));
      expect(zero.isAlertaOrcamentoAtingido, isFalse);
      expect(zero.isOrcamentoEstourado, isFalse);
      expect(zero.healthStatus, equals(FinopsHealthStatus.healthy));
    });

    test('FinOps computed math: costs, percentages, balances and thresholds', () {
      final model = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: 'tenant_epi_01',
        orcamentoMensalBrl: 1000.0,
        alertaOrcamentoPercentual: 80.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 350.0),
        whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 450.0),
        updatedAt: now,
      );

      // Total investment = 350 + 450 = 800
      expect(model.custoTotalAcumuladoBrl, equals(800.0));
      expect(model.totalInvestimentoBrl, equals(800.0));

      // Percent consumed = (800 / 1000) * 100 = 80.0%
      expect(model.percentualOrcamentoConsumido, equals(80.0));
      expect(model.percentualConsumido, equals(80.0));

      // Saldo = 1000 - 800 = 200.0
      expect(model.saldoOrcamentoBrl, equals(200.0));
      expect(model.saldoRestanteBrl, equals(200.0));

      // Alert reached at 80%
      expect(model.isAlertaOrcamentoAtingido, isTrue);
      expect(model.isAlertThresholdReached, isTrue);

      // Not exceeded yet
      expect(model.isOrcamentoEstourado, isFalse);
      expect(model.isBudgetExceeded, isFalse);
      expect(model.healthStatus, equals(FinopsHealthStatus.warning));
    });

    test('Zero budget (orcamentoMensalBrl = 0.0) guards against division-by-zero', () {
      final zeroBudgetModel = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: 'tenant_epi_01',
        orcamentoMensalBrl: 0.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 50.0),
        updatedAt: now,
      );

      expect(zeroBudgetModel.percentualOrcamentoConsumido, equals(0.0));
      expect(zeroBudgetModel.saldoOrcamentoBrl, equals(0.0));
      expect(zeroBudgetModel.isOrcamentoEstourado, isFalse);
      expect(zeroBudgetModel.healthStatus, equals(FinopsHealthStatus.healthy));
    });

    test('Budget exceeded (>100%) triggers exceeded health status and negative balance', () {
      final exceededModel = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: 'tenant_epi_01',
        orcamentoMensalBrl: 500.0,
        iaMetrics: const IaMetrics(custoAcumuladoBrl: 300.0),
        whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 300.0),
        updatedAt: now,
      );

      expect(exceededModel.custoTotalAcumuladoBrl, equals(600.0));
      expect(exceededModel.percentualOrcamentoConsumido, equals(120.0));
      expect(exceededModel.saldoOrcamentoBrl, equals(-100.0));
      expect(exceededModel.isOrcamentoEstourado, isTrue);
      expect(exceededModel.healthStatus, equals(FinopsHealthStatus.exceeded));
    });

    test('competenciaFormatada produces Portuguese month name', () {
      final model = UsageFinopsModel.zeroState(
        tenantId: 't1',
        competencia: '2026_11',
      );
      expect(model.competenciaFormatada, equals('Novembro/2026'));

      final janModel = model.copyWith(competencia: '2027_01');
      expect(janModel.competenciaFormatada, equals('Janeiro/2027'));
    });

    test('Serialization toMap and toFirestoreMap', () {
      final model = UsageFinopsModel(
        competencia: '2026_11',
        tenantId: 'tenant_epi_01',
        orcamentoMensalBrl: 1500.0,
        alertaOrcamentoPercentual: 85.0,
        iaMetrics: const IaMetrics(totalRequests: 50, custoAcumuladoBrl: 25.0),
        whatsappMetrics: const WhatsAppMetrics(totalConversas: 200, custoAcumuladoBrl: 40.0),
        historicoDiario: const [
          HistoricoDiarioItem(dia: 1, custoIa: 10.0, custoWa: 15.0, msgs: 100),
        ],
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['competencia'], equals('2026_11'));
      expect(map['orcamento_mensal_brl'], equals(1500.0));
      expect(map['updated_at'], isA<Timestamp>());

      final firestoreMap = model.toFirestoreMap();
      final reconstructed = UsageFinopsModel.fromMap(firestoreMap);
      expect(reconstructed.competencia, equals(model.competencia));
      expect(reconstructed.custoTotalAcumuladoBrl, equals(model.custoTotalAcumuladoBrl));
      expect(reconstructed.historicoDiario.length, equals(1));
      expect(reconstructed.historicoDiario.first.dia, equals(1));
    });
  });
}
