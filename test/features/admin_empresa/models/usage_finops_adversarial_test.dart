import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/models/usage_finops_model.dart';
import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';

void main() {
  group('Adversarial Test Suite - FinOps & WhatsApp Models', () {
    // =========================================================================
    // Category A: Division by Zero & Negative Budget Values
    // =========================================================================
    group('Category A: Division by Zero & Negative Budget Edge Cases', () {
      test('A.1: orcamentoMensalBrl = 0.0 with 0.0 spend does not produce NaN or Infinity', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 'tenant_zero_budget',
          orcamentoMensalBrl: 0.0,
          updatedAt: DateTime(2026, 11, 8),
        );

        expect(model.percentualOrcamentoConsumido, equals(0.0));
        expect(model.percentualOrcamentoConsumido.isNaN, isFalse);
        expect(model.percentualOrcamentoConsumido.isInfinite, isFalse);
        expect(model.saldoOrcamentoBrl, equals(0.0));
        expect(model.isAlertaOrcamentoAtingido, isFalse);
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.healthy));
      });

      test('A.2: orcamentoMensalBrl = 0.0 with positive spend (custo = 150.0)', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 'tenant_zero_budget_with_spend',
          orcamentoMensalBrl: 0.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 100.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 50.0),
          updatedAt: DateTime(2026, 11, 8),
        );

        expect(model.custoTotalAcumuladoBrl, equals(150.0));
        // Guarded: orcamentoMensalBrl <= 0.0 returns 0.0 to prevent division by zero
        expect(model.percentualOrcamentoConsumido, equals(0.0));
        expect(model.percentualOrcamentoConsumido.isNaN, isFalse);
        expect(model.percentualOrcamentoConsumido.isInfinite, isFalse);
        expect(model.saldoOrcamentoBrl, equals(0.0));
        // Notice: when budget is unconfigured/zero, budget exceeded requires orcamentoMensalBrl > 0.0
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.healthy));
      });

      test('A.3: Negative budget (orcamentoMensalBrl = -500.0) behaves safely without crashing', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 'tenant_negative_budget',
          orcamentoMensalBrl: -500.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 100.0),
          updatedAt: DateTime(2026, 11, 8),
        );

        // Guarded: orcamentoMensalBrl <= 0.0 returns 0.0
        expect(model.percentualOrcamentoConsumido, equals(0.0));
        expect(model.saldoOrcamentoBrl, equals(0.0));
        expect(model.isAlertaOrcamentoAtingido, isFalse);
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.healthy));
      });

      test('A.4: Zero totalRequests in IaMetrics guards custoMedioPorRequest against division by zero', () {
        const metricsWithZeroRequests = IaMetrics(
          totalRequests: 0,
          custoAcumuladoBrl: 50.0,
        );

        expect(metricsWithZeroRequests.custoMedioPorRequest, equals(0.0));
        expect(metricsWithZeroRequests.custoMedioPorRequest.isNaN, isFalse);
        expect(metricsWithZeroRequests.custoMedioPorRequest.isInfinite, isFalse);
      });

      test('A.5: Zero totalConversas in WhatsAppMetrics guards percentualGratuitas against division by zero', () {
        const waZeroConversas = WhatsAppMetrics(
          totalConversas: 0,
          conversasServicoGratuitas: 0,
          custoAcumuladoBrl: 0.0,
        );

        expect(waZeroConversas.percentualGratuitas, equals(0.0));
        expect(waZeroConversas.percentualGratuitas.isNaN, isFalse);
        expect(waZeroConversas.percentualGratuitas.isInfinite, isFalse);
      });
    });

    // =========================================================================
    // Category B: Extreme Numbers & Floating Point Precision
    // =========================================================================
    group('Category B: Extreme Numbers & Float Arithmetic Precision', () {
      test('B.1: Billions of tokens handled cleanly without overflow', () {
        const metrics = IaMetrics(
          tokensInput: 2500000000, // 2.5 Billion
          tokensOutput: 1500000000, // 1.5 Billion
          custoAcumuladoBrl: 12500.0,
        );

        expect(metrics.totalTokens, equals(4000000000));
        expect(metrics.totalTokensFormatado, equals('4000,00M'));
      });

      test('B.2: Trillions of tokens format representation', () {
        const metrics = IaMetrics(
          tokensInput: 5000000000000, // 5 Trillion
          tokensOutput: 4000000000000, // 4 Trillion
        );

        expect(metrics.totalTokens, equals(9000000000000));
        expect(metrics.totalTokensFormatado, equals('9000000,00M'));
      });

      test('B.3: Extreme high financial value formatting', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 'tenant_enterprise',
          orcamentoMensalBrl: 10000000.0, // R$ 10.000.000,00
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 5000000.50),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 3000000.25),
          updatedAt: DateTime(2026, 11, 8),
        );

        expect(model.custoTotalAcumuladoBrl, equals(8000000.75));
        expect(model.custoTotalFormatadoBrl, equals('R\$ 8000000,75'));
        expect(model.saldoOrcamentoBrl, equals(1999999.25));
        expect(model.saldoRestanteFormatadoBrl, equals('R\$ 1999999,25'));
        expect(model.orcamentoFormatadoBrl, equals('R\$ 10000000,00'));
        expect(model.percentualOrcamentoConsumido, closeTo(80.0000075, 0.0001));
        expect(model.isAlertaOrcamentoAtingido, isTrue);
        expect(model.isOrcamentoEstourado, isFalse);
      });

      test('B.4: Sub-cent micro-costs and floating point precision rounding', () {
        const microIa = IaMetrics(custoAcumuladoBrl: 0.0049); // < 1 cent
        expect(microIa.custoFormatadoBrl, equals('R\$ 0,00'));

        const roundedUpIa = IaMetrics(custoAcumuladoBrl: 0.0051);
        expect(roundedUpIa.custoFormatadoBrl, equals('R\$ 0,01'));

        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 'tenant_micro',
          orcamentoMensalBrl: 1000.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 0.1),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 0.2),
          updatedAt: DateTime(2026, 11, 8),
        );

        // IEEE 754 float: 0.1 + 0.2 = 0.30000000000000004
        expect(model.custoTotalAcumuladoBrl, closeTo(0.3, 0.0000001));
        expect(model.custoTotalFormatadoBrl, equals('R\$ 0,30'));
      });
    });

    // =========================================================================
    // Category C: Threshold Boundaries
    // =========================================================================
    group('Category C: Threshold Boundaries (79.99%, 80.00%, 80.01%, 99.99%, 100.00%, 100.01%)', () {
      final baseDate = DateTime(2026, 11, 8);

      test('C.1: At 79.99% consumption -> Alert is NOT triggered, budget NOT exceeded, HEALTHY', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 400.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 399.90),
          updatedAt: baseDate,
        );

        expect(model.custoTotalAcumuladoBrl, closeTo(799.90, 0.001));
        expect(model.percentualOrcamentoConsumido, closeTo(79.99, 0.001));
        expect(model.saldoOrcamentoBrl, closeTo(200.10, 0.001));
        expect(model.isAlertaOrcamentoAtingido, isFalse);
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.healthy));
      });

      test('C.2: At 80.00% consumption -> Alert IS triggered, budget NOT exceeded, WARNING', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 400.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 400.0),
          updatedAt: baseDate,
        );

        expect(model.custoTotalAcumuladoBrl, closeTo(800.00, 0.001));
        expect(model.percentualOrcamentoConsumido, closeTo(80.00, 0.001));
        expect(model.saldoOrcamentoBrl, closeTo(200.00, 0.001));
        expect(model.isAlertaOrcamentoAtingido, isTrue);
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.warning));
      });

      test('C.3: At 80.01% consumption -> Alert IS triggered, budget NOT exceeded, WARNING', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 400.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 400.10),
          updatedAt: baseDate,
        );

        expect(model.custoTotalAcumuladoBrl, closeTo(800.10, 0.001));
        expect(model.percentualOrcamentoConsumido, closeTo(80.01, 0.001));
        expect(model.saldoOrcamentoBrl, closeTo(199.90, 0.001));
        expect(model.isAlertaOrcamentoAtingido, isTrue);
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.warning));
      });

      test('C.4: At 99.99% consumption -> Alert IS triggered, budget NOT exceeded, WARNING', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 500.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 499.90),
          updatedAt: baseDate,
        );

        expect(model.custoTotalAcumuladoBrl, closeTo(999.90, 0.001));
        expect(model.percentualOrcamentoConsumido, closeTo(99.99, 0.001));
        expect(model.saldoOrcamentoBrl, closeTo(0.10, 0.001));
        expect(model.isAlertaOrcamentoAtingido, isTrue);
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.warning));
      });

      test('C.5: At 100.00% exact consumption -> Alert IS triggered, NOT strictly exceeded, WARNING, Saldo = 0.00', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 500.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 500.0),
          updatedAt: baseDate,
        );

        expect(model.custoTotalAcumuladoBrl, closeTo(1000.00, 0.001));
        expect(model.percentualOrcamentoConsumido, closeTo(100.00, 0.001));
        expect(model.saldoOrcamentoBrl, closeTo(0.00, 0.001));
        expect(model.saldoRestanteFormatadoBrl, equals('R\$ 0,00'));
        expect(model.isAlertaOrcamentoAtingido, isTrue);
        // At exactly 100.00%, custo > orcamento is false (not strictly greater)
        expect(model.isOrcamentoEstourado, isFalse);
        expect(model.healthStatus, equals(FinopsHealthStatus.warning));
      });

      test('C.6: At 100.01% consumption -> Budget IS strictly exceeded, EXCEEDED, Saldo < 0.00', () {
        final model = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 80.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 500.0),
          whatsappMetrics: const WhatsAppMetrics(custoAcumuladoBrl: 500.10),
          updatedAt: baseDate,
        );

        expect(model.custoTotalAcumuladoBrl, closeTo(1000.10, 0.001));
        expect(model.percentualOrcamentoConsumido, closeTo(100.01, 0.001));
        expect(model.saldoOrcamentoBrl, closeTo(-0.10, 0.001));
        expect(model.saldoRestanteFormatadoBrl, equals('R\$ -0,10'));
        expect(model.isAlertaOrcamentoAtingido, isTrue);
        expect(model.isOrcamentoEstourado, isTrue);
        expect(model.healthStatus, equals(FinopsHealthStatus.exceeded));
      });

      test('C.7: Custom alert thresholds (50% and 95%)', () {
        // Custom 50%
        final model50 = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 50.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 500.0),
          updatedAt: baseDate,
        );
        expect(model50.percentualOrcamentoConsumido, equals(50.0));
        expect(model50.isAlertaOrcamentoAtingido, isTrue);
        expect(model50.healthStatus, equals(FinopsHealthStatus.warning));

        // Custom 95%
        final model95 = UsageFinopsModel(
          competencia: '2026_11',
          tenantId: 't1',
          orcamentoMensalBrl: 1000.0,
          alertaOrcamentoPercentual: 95.0,
          iaMetrics: const IaMetrics(custoAcumuladoBrl: 940.0),
          updatedAt: baseDate,
        );
        expect(model95.percentualOrcamentoConsumido, equals(94.0));
        expect(model95.isAlertaOrcamentoAtingido, isFalse);
        expect(model95.healthStatus, equals(FinopsHealthStatus.healthy));
      });
    });

    // =========================================================================
    // Category D: Zero-State Model Default Values
    // =========================================================================
    group('Category D: Zero-State Model Default Values', () {
      test('D.1: UsageFinopsModel.zeroState has clean non-null 0.0 values, empty lists and valid strings', () {
        final zero = UsageFinopsModel.zeroState(
          tenantId: 'tenant_test_zero',
          competencia: '2026_11',
        );

        expect(zero.tenantId, equals('tenant_test_zero'));
        expect(zero.competencia, equals('2026_11'));
        expect(zero.competenciaFormatada, equals('Novembro/2026'));
        expect(zero.orcamentoMensalBrl, equals(1000.0));
        expect(zero.alertaOrcamentoPercentual, equals(80.0));
        expect(zero.custoTotalAcumuladoBrl, equals(0.0));
        expect(zero.percentualOrcamentoConsumido, equals(0.0));
        expect(zero.saldoOrcamentoBrl, equals(1000.0));
        expect(zero.isAlertaOrcamentoAtingido, isFalse);
        expect(zero.isOrcamentoEstourado, isFalse);
        expect(zero.healthStatus, equals(FinopsHealthStatus.healthy));
        expect(zero.custoTotalFormatadoBrl, equals('R\$ 0,00'));
        expect(zero.saldoRestanteFormatadoBrl, equals('R\$ 1000,00'));
        expect(zero.orcamentoFormatadoBrl, equals('R\$ 1000,00'));
        expect(zero.historicoDiario, isEmpty);

        // Nested IaMetrics zero-state defaults
        expect(zero.iaMetrics.totalRequests, equals(0));
        expect(zero.iaMetrics.tokensInput, equals(0));
        expect(zero.iaMetrics.tokensOutput, equals(0));
        expect(zero.iaMetrics.totalTokens, equals(0));
        expect(zero.iaMetrics.audiosTranscritosMinutos, equals(0));
        expect(zero.iaMetrics.documentosAnalisados, equals(0));
        expect(zero.iaMetrics.custoAcumuladoBrl, equals(0.0));
        expect(zero.iaMetrics.economiaEstimadaHorasHumanas, equals(0.0));
        expect(zero.iaMetrics.totalTokensFormatado, equals('0'));
        expect(zero.iaMetrics.custoFormatadoBrl, equals('R\$ 0,00'));
        expect(zero.iaMetrics.custoMedioPorRequest, equals(0.0));

        // Nested WhatsAppMetrics zero-state defaults
        expect(zero.whatsappMetrics.totalConversas, equals(0));
        expect(zero.whatsappMetrics.conversasServicoGratuitas, equals(0));
        expect(zero.whatsappMetrics.conversasUtilidade, equals(0));
        expect(zero.whatsappMetrics.conversasMarketing, equals(0));
        expect(zero.whatsappMetrics.conversasAutenticacao, equals(0));
        expect(zero.whatsappMetrics.conversasPagas, equals(0));
        expect(zero.whatsappMetrics.percentualGratuitas, equals(0.0));
        expect(zero.whatsappMetrics.custoAcumuladoBrl, equals(0.0));
        expect(zero.whatsappMetrics.custoFormatadoBrl, equals('R\$ 0,00'));
      });

      test('D.2: WhatsAppNumberModel defaults are secure and resilient', () {
        final now = DateTime(2026, 11, 8, 12, 0);
        final number = WhatsAppNumberModel(
          id: '10987654321',
          tenantId: 'tenant_01',
          wabaId: 'waba_12345',
          phoneNumberId: '10987654321',
          displayPhoneNumber: '+55 11 98877-6655',
          verifiedName: 'Empresa Teste',
          qualityRating: MetaQualityRating.green,
          messagingLimitTier: MetaMessagingTier.tier1k,
          connectedAt: now,
          lastSyncAt: now,
        );

        expect(number.codeVerificationStatus, equals('VERIFIED'));
        expect(number.status, equals('connected'));
        expect(number.webhookSubscribed, isTrue);
        expect(number.isDefault, isFalse);
        expect(number.iaAtivaNesteNumero, isTrue);
        expect(number.connectedByUid, isEmpty);
        expect(number.isOperational, isTrue);
        expect(number.isHighQuality, isTrue);
        expect(number.isVerified, isTrue);
        expect(number.isDisconnected, isFalse);
        expect(number.statusLabel, equals('Conectado'));
      });
    });

    // =========================================================================
    // Category E: Deserialization With Unexpected Field Types
    // =========================================================================
    group('Category E: Deserialization with Unexpected Field Types', () {
      test('E.1: Integer values provided in double fields parse smoothly without TypeError', () {
        final rawMap = {
          'competencia': '2026_11',
          'tenant_id': 't_ints',
          'orcamento_mensal_brl': 2000, // int instead of double
          'alerta_orcamento_percentual': 85, // int instead of double
          'ia_metrics': {
            'total_requests': 50,
            'tokens_input': 1000,
            'tokens_output': 500,
            'custo_acumulado_brl': 100, // int instead of double
            'economia_estimada_horas_humanas': 20, // int instead of double
          },
          'whatsapp_metrics': {
            'total_conversas': 200,
            'custo_acumulado_brl': 50, // int instead of double
          },
          'historico_diario': [
            {
              'dia': 1,
              'custo_ia': 10, // int instead of double
              'custo_wa': 5, // int instead of double
              'msgs': 50,
            }
          ],
          'updated_at': 1794141000000, // int epoch timestamp
        };

        final model = UsageFinopsModel.fromMap(rawMap);
        expect(model.orcamentoMensalBrl, equals(2000.0));
        expect(model.alertaOrcamentoPercentual, equals(85.0));
        expect(model.iaMetrics.custoAcumuladoBrl, equals(100.0));
        expect(model.iaMetrics.economiaEstimadaHorasHumanas, equals(20.0));
        expect(model.whatsappMetrics.custoAcumuladoBrl, equals(50.0));
        expect(model.historicoDiario.length, equals(1));
        expect(model.historicoDiario.first.custoIa, equals(10.0));
        expect(model.historicoDiario.first.custoWa, equals(5.0));
        expect(model.historicoDiario.first.custoTotal, equals(15.0));
      });

      test('E.2: Double values provided in integer fields parse smoothly without TypeError', () {
        final rawMap = {
          'competencia': '2026_11',
          'tenant_id': 't_doubles',
          'ia_metrics': {
            'total_requests': 50.0, // double instead of int
            'tokens_input': 1000.0, // double instead of int
            'tokens_output': 500.0, // double instead of int
            'audios_transcritos_minutos': 15.0,
            'documentos_analisados': 5.0,
          },
          'whatsapp_metrics': {
            'total_conversas': 300.0, // double instead of int
            'conversas_servico_gratuitas': 200.0,
            'conversas_utilidade': 50.0,
            'conversas_marketing': 40.0,
            'conversas_autenticacao': 10.0,
          },
          'historico_diario': [
            {
              'dia': 5.0, // double instead of int
              'custo_ia': 2.5,
              'custo_wa': 1.5,
              'msgs': 30.0, // double instead of int
            }
          ],
        };

        final model = UsageFinopsModel.fromMap(rawMap);
        expect(model.iaMetrics.totalRequests, equals(50));
        expect(model.iaMetrics.tokensInput, equals(1000));
        expect(model.iaMetrics.tokensOutput, equals(500));
        expect(model.iaMetrics.audiosTranscritosMinutos, equals(15));
        expect(model.iaMetrics.documentosAnalisados, equals(5));

        expect(model.whatsappMetrics.totalConversas, equals(300));
        expect(model.whatsappMetrics.conversasServicoGratuitas, equals(200));
        expect(model.whatsappMetrics.conversasUtilidade, equals(50));
        expect(model.whatsappMetrics.conversasMarketing, equals(40));
        expect(model.whatsappMetrics.conversasAutenticacao, equals(10));

        expect(model.historicoDiario.first.dia, equals(5));
        expect(model.historicoDiario.first.msgs, equals(30));
      });

      test('E.3: Heterogeneous date representations (Timestamp, DateTime, ISO string, epoch int, null, malformed)', () {
        final now = DateTime(2026, 11, 8, 14, 0);

        // 1. Timestamp
        final mTimestamp = UsageFinopsModel.fromMap({
          'updated_at': Timestamp.fromDate(now),
        });
        expect(mTimestamp.updatedAt, equals(now));

        // 2. DateTime
        final mDateTime = UsageFinopsModel.fromMap({
          'updated_at': now,
        });
        expect(mDateTime.updatedAt, equals(now));

        // 3. String ISO 8601
        final mIso = UsageFinopsModel.fromMap({
          'updated_at': '2026-11-08T14:00:00.000',
        });
        expect(mIso.updatedAt.year, equals(2026));
        expect(mIso.updatedAt.month, equals(11));

        // 4. Int epoch ms
        final mEpoch = UsageFinopsModel.fromMap({
          'updated_at': now.millisecondsSinceEpoch,
        });
        expect(mEpoch.updatedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // 5. null -> defaults to now without crash
        final mNull = UsageFinopsModel.fromMap({'updated_at': null});
        expect(mNull.updatedAt, isNotNull);

        // 6. Malformed string -> fallback to now without crash
        final mMalformed = UsageFinopsModel.fromMap({'updated_at': 'not-a-date'});
        expect(mMalformed.updatedAt, isNotNull);
      });

      test('E.4: WhatsAppNumberModel heterogeneous dates and resilient enums', () {
        final now = DateTime(2026, 11, 8, 12, 0);

        final rawNumber = {
          'id': 'phone_999',
          'tenant_id': 'tenant_abc',
          'display_phone_number': '+55 11 91234-5678',
          'quality_rating': '  gReEn  ', // weird casing and whitespace
          'messaging_limit_tier': 'tier_10k', // lowercase
          'connected_at': Timestamp.fromDate(now),
          'last_sync_at': '2026-11-08T12:00:00.000Z',
          'updated_at': now.millisecondsSinceEpoch,
        };

        final number = WhatsAppNumberModel.fromMap(rawNumber);
        expect(number.qualityRating, equals(MetaQualityRating.green));
        expect(number.messagingLimitTier, equals(MetaMessagingTier.tier10k));
        expect(number.connectedAt, equals(now));
        expect(number.lastSyncAt.year, equals(2026));
        expect(number.updatedAt, isNotNull);

        // Unrecognized enums default cleanly to unknown
        final rawCorrupt = {
          'id': 'phone_corrupt',
          'quality_rating': 'INVALID_METRIC_VALUE',
          'messaging_limit_tier': 'TIER_SUPER_EXTREME',
        };
        final corruptNumber = WhatsAppNumberModel.fromMap(rawCorrupt);
        expect(corruptNumber.qualityRating, equals(MetaQualityRating.unknown));
        expect(corruptNumber.messagingLimitTier, equals(MetaMessagingTier.unknown));
      });

      test('E.5: Corrupt and mixed elements in historico_diario list are filtered safely', () {
        final rawMap = {
          'competencia': '2026_11',
          'historico_diario': [
            null,
            'string_instead_of_map',
            12345,
            {'dia': 1, 'custo_ia': 2.0, 'custo_wa': 1.0, 'msgs': 10},
            true,
          ],
        };

        final model = UsageFinopsModel.fromMap(rawMap);
        expect(model.historicoDiario.length, equals(1));
        expect(model.historicoDiario.first.dia, equals(1));
        expect(model.historicoDiario.first.custoTotal, equals(3.0));
      });

      test('E.6: Completely empty map deserializes safely with zero defaults', () {
        final model = UsageFinopsModel.fromMap({});
        expect(model.competencia, isEmpty);
        expect(model.tenantId, isEmpty);
        expect(model.orcamentoMensalBrl, equals(1000.0));
        expect(model.alertaOrcamentoPercentual, equals(80.0));
        expect(model.custoTotalAcumuladoBrl, equals(0.0));
        expect(model.historicoDiario, isEmpty);

        final number = WhatsAppNumberModel.fromMap({});
        expect(number.id, isEmpty);
        expect(number.tenantId, isEmpty);
        expect(number.qualityRating, equals(MetaQualityRating.unknown));
        expect(number.messagingLimitTier, equals(MetaMessagingTier.unknown));
        expect(number.codeVerificationStatus, equals('VERIFIED'));
      });
    });
  });
}
