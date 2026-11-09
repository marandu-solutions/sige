import 'meta_mock_contracts.dart';

class FinOpsTestFixtures {
  static const String tenantEpiId = 'tenant_epi_01';
  static const String tenantSolarId = 'tenant_solar_02';

  // Sample OAuth results
  static MetaEmbeddedSignupResult sampleSuccessSignupResult() {
    return MetaEmbeddedSignupResult.success(
      code: 'AQD7g8K1Z9P4m0X_mock_oauth_code_12345',
      wabaId: '998877665544332',
      phoneNumberId: '109283746511223',
      businessId: 'biz_epi_forte_global',
    );
  }

  static MetaEmbeddedSignupResult sampleCancelledSignupResult() {
    return MetaEmbeddedSignupResult.cancelled(
      reason: 'Janela fechada pelo usuário antes da confirmação do número.',
    );
  }

  static MetaEmbeddedSignupResult sampleErrorSignupResult() {
    return MetaEmbeddedSignupResult.error(
      'Popup bloqueado pelas diretrizes do navegador.',
    );
  }

  // Sample WhatsApp numbers
  static WhatsAppNumberModelContract epiPrimaryNumber() {
    return WhatsAppNumberModelContract(
      id: '109283746511223',
      tenantId: tenantEpiId,
      wabaId: '998877665544332',
      phoneNumberId: '109283746511223',
      displayPhoneNumber: '+55 11 98877-6655',
      verifiedName: 'EPI Forte Equipamentos Comercial',
      qualityRating: MetaQualityRating.green,
      messagingLimitTier: MetaMessagingTier.tier10k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      isDefault: true,
      iaAtivaNesteNumero: true,
      connectedByUid: 'uid_gestor_epi_01',
      connectedAt: DateTime.parse('2026-11-01T10:00:00Z'),
      lastSyncAt: DateTime.parse('2026-11-08T15:00:00Z'),
    );
  }

  static WhatsAppNumberModelContract epiSecondaryNumber() {
    return WhatsAppNumberModelContract(
      id: '887766554433',
      tenantId: tenantEpiId,
      wabaId: '998877665544332',
      phoneNumberId: '887766554433',
      displayPhoneNumber: '+55 11 3344-5566',
      verifiedName: 'EPI Forte Pós-Venda & SAC',
      qualityRating: MetaQualityRating.green,
      messagingLimitTier: MetaMessagingTier.tier1k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      isDefault: false,
      iaAtivaNesteNumero: false,
      connectedByUid: 'uid_gestor_epi_01',
      connectedAt: DateTime.parse('2026-11-03T14:30:00Z'),
      lastSyncAt: DateTime.parse('2026-11-08T15:00:00Z'),
    );
  }

  static WhatsAppNumberModelContract solarPrimaryNumber() {
    return WhatsAppNumberModelContract(
      id: '332211445566',
      tenantId: tenantSolarId,
      wabaId: '554433221100998',
      phoneNumberId: '332211445566',
      displayPhoneNumber: '+55 81 99988-7711',
      verifiedName: 'Solarium Solar Energia',
      qualityRating: MetaQualityRating.yellow,
      messagingLimitTier: MetaMessagingTier.tier1k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      isDefault: true,
      iaAtivaNesteNumero: true,
      connectedByUid: 'uid_gestor_solar_01',
      connectedAt: DateTime.parse('2026-11-05T09:15:00Z'),
      lastSyncAt: DateTime.parse('2026-11-08T15:00:00Z'),
    );
  }

  // FinOps Monthly Rollups
  static FinOpsUsageModelContract standardEpiNovemberRollup() {
    return FinOpsUsageModelContract(
      competencia: '2026_11',
      tenantId: tenantEpiId,
      orcamentoMensalBrl: 1500.00,
      alertaOrcamentoPercentual: 80.0,
      iaMetrics: const IaMetricsContract(
        totalRequests: 4280,
        tokensInput: 1850400,
        tokensOutput: 620100,
        audiosTranscritosMinutos: 142,
        documentosAnalisados: 85,
        custoAcumuladoBrl: 214.60,
        economiaEstimadaHorasHumanas: 118.5,
      ),
      whatsappMetrics: const WhatsAppMetricsContract(
        totalConversas: 1940,
        conversasServicoGratuitas: 1420,
        conversasUtilidade: 310,
        conversasMarketing: 180,
        conversasAutenticacao: 30,
        custoAcumuladoBrl: 348.20,
      ),
      historicoDiario: const [
        DailyUsageContract(dia: 1, custoIa: 18.40, custoWa: 29.10, msgs: 165),
        DailyUsageContract(dia: 2, custoIa: 22.10, custoWa: 34.50, msgs: 210),
        DailyUsageContract(dia: 3, custoIa: 25.80, custoWa: 41.20, msgs: 230),
      ],
      updatedAt: DateTime.parse('2026-11-08T15:00:00Z'),
    );
  }

  static FinOpsUsageModelContract zeroStateRollup({
    required String tenantId,
    required String competencia,
  }) {
    return FinOpsUsageModelContract(
      competencia: competencia,
      tenantId: tenantId,
      orcamentoMensalBrl: 1000.0,
      alertaOrcamentoPercentual: 80.0,
      iaMetrics: const IaMetricsContract(),
      whatsappMetrics: const WhatsAppMetricsContract(),
      historicoDiario: const [],
      updatedAt: DateTime.parse('2026-11-01T00:00:00Z'),
    );
  }

  static FinOpsUsageModelContract nearThresholdRollup() {
    return FinOpsUsageModelContract(
      competencia: '2026_11',
      tenantId: tenantEpiId,
      orcamentoMensalBrl: 1000.0,
      alertaOrcamentoPercentual: 80.0,
      iaMetrics: const IaMetricsContract(
        custoAcumuladoBrl: 400.0,
      ),
      whatsappMetrics: const WhatsAppMetricsContract(
        custoAcumuladoBrl: 400.0, // 400 + 400 = 800 (exactly 80%)
      ),
      updatedAt: DateTime.parse('2026-11-08T15:00:00Z'),
    );
  }

  static FinOpsUsageModelContract exceededBudgetRollup() {
    return FinOpsUsageModelContract(
      competencia: '2026_11',
      tenantId: tenantEpiId,
      orcamentoMensalBrl: 1000.0,
      alertaOrcamentoPercentual: 80.0,
      iaMetrics: const IaMetricsContract(
        custoAcumuladoBrl: 550.0,
      ),
      whatsappMetrics: const WhatsAppMetricsContract(
        custoAcumuladoBrl: 500.0, // 550 + 500 = 1050 (105%)
      ),
      updatedAt: DateTime.parse('2026-11-08T15:00:00Z'),
    );
  }
}
