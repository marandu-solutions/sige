/// Meta & WhatsApp Embedded Signup Contract Schemas & DTOs
/// Authoritative reference: PROJECT.md § Interface Contracts & bmad_mds/md07
library;

enum MetaSignupStatus {
  success,
  cancelled,
  error,
}

enum MetaSignupStep {
  idle,
  authenticatingInMeta,
  capturingSessionIds,
  exchangingTokenAndSubscribing,
  completed,
  error,
  cancelled,
}

enum MetaQualityRating {
  green,
  yellow,
  red,
  unknown;

  static MetaQualityRating fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'GREEN':
        return MetaQualityRating.green;
      case 'YELLOW':
        return MetaQualityRating.yellow;
      case 'RED':
        return MetaQualityRating.red;
      default:
        return MetaQualityRating.unknown;
    }
  }

  String toApiValue() => name.toUpperCase();
}

enum MetaMessagingTier {
  tier50,
  tier250,
  tier1k,
  tier10k,
  tier100k,
  tierUnlimited,
  unknown;

  static MetaMessagingTier fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'TIER_50':
        return MetaMessagingTier.tier50;
      case 'TIER_250':
        return MetaMessagingTier.tier250;
      case 'TIER_1K':
        return MetaMessagingTier.tier1k;
      case 'TIER_10K':
        return MetaMessagingTier.tier10k;
      case 'TIER_100K':
        return MetaMessagingTier.tier100k;
      case 'TIER_UNLIMITED':
        return MetaMessagingTier.tierUnlimited;
      default:
        return MetaMessagingTier.unknown;
    }
  }

  String toApiValue() {
    switch (this) {
      case MetaMessagingTier.tier50:
        return 'TIER_50';
      case MetaMessagingTier.tier250:
        return 'TIER_250';
      case MetaMessagingTier.tier1k:
        return 'TIER_1K';
      case MetaMessagingTier.tier10k:
        return 'TIER_10K';
      case MetaMessagingTier.tier100k:
        return 'TIER_100K';
      case MetaMessagingTier.tierUnlimited:
        return 'TIER_UNLIMITED';
      case MetaMessagingTier.unknown:
        return 'UNKNOWN';
    }
  }

  int get maxConversationsPer24h {
    switch (this) {
      case MetaMessagingTier.tier50:
        return 50;
      case MetaMessagingTier.tier250:
        return 250;
      case MetaMessagingTier.tier1k:
        return 1000;
      case MetaMessagingTier.tier10k:
        return 10000;
      case MetaMessagingTier.tier100k:
        return 100000;
      case MetaMessagingTier.tierUnlimited:
        return 1000000;
      case MetaMessagingTier.unknown:
        return 0;
    }
  }
}

/// DTO returned by Meta Embedded Signup Bridge
class MetaEmbeddedSignupResult {
  final MetaSignupStatus status;
  final String? code;
  final String? wabaId;
  final String? phoneNumberId;
  final String? businessId;
  final String? errorMessage;

  const MetaEmbeddedSignupResult({
    required this.status,
    this.code,
    this.wabaId,
    this.phoneNumberId,
    this.businessId,
    this.errorMessage,
  });

  bool get isSuccess => status == MetaSignupStatus.success;
  bool get isCancelled => status == MetaSignupStatus.cancelled;
  bool get isError => status == MetaSignupStatus.error;

  factory MetaEmbeddedSignupResult.success({
    required String code,
    required String wabaId,
    required String phoneNumberId,
    String? businessId,
  }) {
    return MetaEmbeddedSignupResult(
      status: MetaSignupStatus.success,
      code: code,
      wabaId: wabaId,
      phoneNumberId: phoneNumberId,
      businessId: businessId,
    );
  }

  factory MetaEmbeddedSignupResult.cancelled({String? reason}) {
    return MetaEmbeddedSignupResult(
      status: MetaSignupStatus.cancelled,
      errorMessage: reason ?? 'Fluxo cancelado pelo usuário antes da conclusão.',
    );
  }

  factory MetaEmbeddedSignupResult.error(String message) {
    return MetaEmbeddedSignupResult(
      status: MetaSignupStatus.error,
      errorMessage: message,
    );
  }

  factory MetaEmbeddedSignupResult.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String?)?.toUpperCase() ?? 'ERROR';
    MetaSignupStatus status;
    if (statusStr == 'SUCCESS') {
      status = MetaSignupStatus.success;
    } else if (statusStr == 'CANCELLED') {
      status = MetaSignupStatus.cancelled;
    } else {
      status = MetaSignupStatus.error;
    }

    return MetaEmbeddedSignupResult(
      status: status,
      code: json['code'] as String?,
      wabaId: json['waba_id'] as String?,
      phoneNumberId: json['phone_number_id'] as String?,
      businessId: json['business_id'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name.toUpperCase(),
      'code': code,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'business_id': businessId,
      'error_message': errorMessage,
    };
  }
}

/// Domain contract for a connected WhatsApp number (tenant/{tenantId}/whatsapp_numbers/{id})
class WhatsAppNumberModelContract {
  final String id;
  final String tenantId;
  final String wabaId;
  final String phoneNumberId;
  final String displayPhoneNumber;
  final String verifiedName;
  final MetaQualityRating qualityRating;
  final MetaMessagingTier messagingLimitTier;
  final String codeVerificationStatus;
  final String status;
  final bool webhookSubscribed;
  final bool isDefault;
  final bool iaAtivaNesteNumero;
  final String connectedByUid;
  final DateTime connectedAt;
  final DateTime lastSyncAt;

  const WhatsAppNumberModelContract({
    required this.id,
    required this.tenantId,
    required this.wabaId,
    required this.phoneNumberId,
    required this.displayPhoneNumber,
    required this.verifiedName,
    required this.qualityRating,
    required this.messagingLimitTier,
    required this.codeVerificationStatus,
    required this.status,
    required this.webhookSubscribed,
    this.isDefault = false,
    this.iaAtivaNesteNumero = true,
    required this.connectedByUid,
    required this.connectedAt,
    required this.lastSyncAt,
  });

  bool get isOperational => status == 'connected' && webhookSubscribed;
  bool get isHighQuality => qualityRating == MetaQualityRating.green;
  bool get isVerified => codeVerificationStatus.toUpperCase() == 'VERIFIED';

  WhatsAppNumberModelContract copyWith({
    String? displayPhoneNumber,
    String? verifiedName,
    MetaQualityRating? qualityRating,
    MetaMessagingTier? messagingLimitTier,
    String? codeVerificationStatus,
    String? status,
    bool? webhookSubscribed,
    bool? isDefault,
    bool? iaAtivaNesteNumero,
    DateTime? lastSyncAt,
  }) {
    return WhatsAppNumberModelContract(
      id: id,
      tenantId: tenantId,
      wabaId: wabaId,
      phoneNumberId: phoneNumberId,
      displayPhoneNumber: displayPhoneNumber ?? this.displayPhoneNumber,
      verifiedName: verifiedName ?? this.verifiedName,
      qualityRating: qualityRating ?? this.qualityRating,
      messagingLimitTier: messagingLimitTier ?? this.messagingLimitTier,
      codeVerificationStatus: codeVerificationStatus ?? this.codeVerificationStatus,
      status: status ?? this.status,
      webhookSubscribed: webhookSubscribed ?? this.webhookSubscribed,
      isDefault: isDefault ?? this.isDefault,
      iaAtivaNesteNumero: iaAtivaNesteNumero ?? this.iaAtivaNesteNumero,
      connectedByUid: connectedByUid,
      connectedAt: connectedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  factory WhatsAppNumberModelContract.fromFirestoreMap(
    String docId,
    Map<String, dynamic> data,
  ) {
    return WhatsAppNumberModelContract(
      id: docId,
      tenantId: data['tenant_id'] as String? ?? '',
      wabaId: data['waba_id'] as String? ?? '',
      phoneNumberId: data['phone_number_id'] as String? ?? docId,
      displayPhoneNumber: data['display_phone_number'] as String? ?? '',
      verifiedName: data['verified_name'] as String? ?? 'WhatsApp Business',
      qualityRating: MetaQualityRating.fromString(data['quality_rating'] as String?),
      messagingLimitTier: MetaMessagingTier.fromString(data['messaging_limit_tier'] as String?),
      codeVerificationStatus: data['code_verification_status'] as String? ?? 'VERIFIED',
      status: data['status'] as String? ?? 'connected',
      webhookSubscribed: data['webhook_subscribed'] as bool? ?? false,
      isDefault: data['is_default'] as bool? ?? false,
      iaAtivaNesteNumero: data['ia_ativa_neste_numero'] as bool? ?? true,
      connectedByUid: data['connected_by_uid'] as String? ?? '',
      connectedAt: data['connected_at'] != null
          ? DateTime.tryParse(data['connected_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastSyncAt: data['last_sync_at'] != null
          ? DateTime.tryParse(data['last_sync_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'display_phone_number': displayPhoneNumber,
      'verified_name': verifiedName,
      'quality_rating': qualityRating.toApiValue(),
      'messaging_limit_tier': messagingLimitTier.toApiValue(),
      'code_verification_status': codeVerificationStatus,
      'status': status,
      'webhook_subscribed': webhookSubscribed,
      'is_default': isDefault,
      'ia_ativa_neste_numero': iaAtivaNesteNumero,
      'connected_by_uid': connectedByUid,
      'connected_at': connectedAt.toIso8601String(),
      'last_sync_at': lastSyncAt.toIso8601String(),
    };
  }
}

/// FinOps metrics for AI consumption
class IaMetricsContract {
  final int totalRequests;
  final int tokensInput;
  final int tokensOutput;
  final int audiosTranscritosMinutos;
  final int documentosAnalisados;
  final double custoAcumuladoBrl;
  final double economiaEstimadaHorasHumanas;

  const IaMetricsContract({
    this.totalRequests = 0,
    this.tokensInput = 0,
    this.tokensOutput = 0,
    this.audiosTranscritosMinutos = 0,
    this.documentosAnalisados = 0,
    this.custoAcumuladoBrl = 0.0,
    this.economiaEstimadaHorasHumanas = 0.0,
  });

  int get totalTokens => tokensInput + tokensOutput;

  factory IaMetricsContract.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const IaMetricsContract();
    return IaMetricsContract(
      totalRequests: (data['total_requests'] as num?)?.toInt() ?? 0,
      tokensInput: (data['tokens_input'] as num?)?.toInt() ?? 0,
      tokensOutput: (data['tokens_output'] as num?)?.toInt() ?? 0,
      audiosTranscritosMinutos: (data['audios_transcritos_minutos'] as num?)?.toInt() ?? 0,
      documentosAnalisados: (data['documentos_analisados'] as num?)?.toInt() ?? 0,
      custoAcumuladoBrl: (data['custo_acumulado_brl'] as num?)?.toDouble() ?? 0.0,
      economiaEstimadaHorasHumanas: (data['economia_estimada_horas_humanas'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_requests': totalRequests,
      'tokens_input': tokensInput,
      'tokens_output': tokensOutput,
      'audios_transcritos_minutos': audiosTranscritosMinutos,
      'documentos_analisados': documentosAnalisados,
      'custo_acumulado_brl': custoAcumuladoBrl,
      'economia_estimada_horas_humanas': economiaEstimadaHorasHumanas,
    };
  }
}

/// FinOps metrics for WhatsApp messaging
class WhatsAppMetricsContract {
  final int totalConversas;
  final int conversasServicoGratuitas;
  final int conversasUtilidade;
  final int conversasMarketing;
  final int conversasAutenticacao;
  final double custoAcumuladoBrl;

  const WhatsAppMetricsContract({
    this.totalConversas = 0,
    this.conversasServicoGratuitas = 0,
    this.conversasUtilidade = 0,
    this.conversasMarketing = 0,
    this.conversasAutenticacao = 0,
    this.custoAcumuladoBrl = 0.0,
  });

  int get conversasPagas =>
      conversasUtilidade + conversasMarketing + conversasAutenticacao;

  factory WhatsAppMetricsContract.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const WhatsAppMetricsContract();
    return WhatsAppMetricsContract(
      totalConversas: (data['total_conversas'] as num?)?.toInt() ?? 0,
      conversasServicoGratuitas: (data['conversas_servico_gratuitas'] as num?)?.toInt() ?? 0,
      conversasUtilidade: (data['conversas_utilidade'] as num?)?.toInt() ?? 0,
      conversasMarketing: (data['conversas_marketing'] as num?)?.toInt() ?? 0,
      conversasAutenticacao: (data['conversas_autenticacao'] as num?)?.toInt() ?? 0,
      custoAcumuladoBrl: (data['custo_acumulado_brl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_conversas': totalConversas,
      'conversas_servico_gratuitas': conversasServicoGratuitas,
      'conversas_utilidade': conversasUtilidade,
      'conversas_marketing': conversasMarketing,
      'conversas_autenticacao': conversasAutenticacao,
      'custo_acumulado_brl': custoAcumuladoBrl,
    };
  }
}

/// Daily cost telemetry entry
class DailyUsageContract {
  final int dia;
  final double custoIa;
  final double custoWa;
  final int msgs;

  const DailyUsageContract({
    required this.dia,
    required this.custoIa,
    required this.custoWa,
    required this.msgs,
  });

  double get custoTotal => custoIa + custoWa;

  factory DailyUsageContract.fromMap(Map<String, dynamic> data) {
    return DailyUsageContract(
      dia: (data['dia'] as num?)?.toInt() ?? 1,
      custoIa: (data['custo_ia'] as num?)?.toDouble() ?? 0.0,
      custoWa: (data['custo_wa'] as num?)?.toDouble() ?? 0.0,
      msgs: (data['msgs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dia': dia,
      'custo_ia': custoIa,
      'custo_wa': custoWa,
      'msgs': msgs,
    };
  }
}

/// Monthly FinOps Rollup Contract (tenant/{tenantId}/usage_metrics/{YYYY_MM})
class FinOpsUsageModelContract {
  final String competencia;
  final String tenantId;
  final double orcamentoMensalBrl;
  final double alertaOrcamentoPercentual;
  final IaMetricsContract iaMetrics;
  final WhatsAppMetricsContract whatsappMetrics;
  final List<DailyUsageContract> historicoDiario;
  final DateTime updatedAt;

  const FinOpsUsageModelContract({
    required this.competencia,
    required this.tenantId,
    this.orcamentoMensalBrl = 1000.0,
    this.alertaOrcamentoPercentual = 80.0,
    this.iaMetrics = const IaMetricsContract(),
    this.whatsappMetrics = const WhatsAppMetricsContract(),
    this.historicoDiario = const [],
    required this.updatedAt,
  });

  double get totalInvestimentoBrl =>
      iaMetrics.custoAcumuladoBrl + whatsappMetrics.custoAcumuladoBrl;

  double get percentualConsumido {
    if (orcamentoMensalBrl <= 0.0) return 0.0;
    return (totalInvestimentoBrl / orcamentoMensalBrl) * 100.0;
  }

  double get saldoRestanteBrl => orcamentoMensalBrl - totalInvestimentoBrl;

  bool get isAlertThresholdReached =>
      percentualConsumido >= alertaOrcamentoPercentual;

  bool get isBudgetExceeded => totalInvestimentoBrl > orcamentoMensalBrl;

  factory FinOpsUsageModelContract.fromFirestoreMap(
    String competencia,
    Map<String, dynamic> data,
  ) {
    final rawHistorico = data['historico_diario'] as List<dynamic>? ?? [];
    final historico = rawHistorico
        .map((item) => DailyUsageContract.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();

    return FinOpsUsageModelContract(
      competencia: competencia,
      tenantId: data['tenant_id'] as String? ?? '',
      orcamentoMensalBrl: (data['orcamento_mensal_brl'] as num?)?.toDouble() ?? 1000.0,
      alertaOrcamentoPercentual: (data['alerta_orcamento_percentual'] as num?)?.toDouble() ?? 80.0,
      iaMetrics: IaMetricsContract.fromMap(
        data['ia_metrics'] as Map<String, dynamic>?,
      ),
      whatsappMetrics: WhatsAppMetricsContract.fromMap(
        data['whatsapp_metrics'] as Map<String, dynamic>?,
      ),
      historicoDiario: historico,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'competencia': competencia,
      'tenant_id': tenantId,
      'orcamento_mensal_brl': orcamentoMensalBrl,
      'alerta_orcamento_percentual': alertaOrcamentoPercentual,
      'ia_metrics': iaMetrics.toMap(),
      'whatsapp_metrics': whatsappMetrics.toMap(),
      'historico_diario': historicoDiario.map((e) => e.toMap()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Secret vault record schema: tenant_secrets/{tenantId}/whatsapp_tokens/{phoneNumberId}
class SecretVaultRecordContract {
  final String tenantId;
  final String wabaId;
  final String phoneNumberId;
  final String accessToken;
  final String tokenType;
  final List<String> scopes;
  final DateTime updatedAt;

  const SecretVaultRecordContract({
    required this.tenantId,
    required this.wabaId,
    required this.phoneNumberId,
    required this.accessToken,
    this.tokenType = 'system_user_permanent',
    this.scopes = const [
      'whatsapp_business_management',
      'whatsapp_business_messaging',
    ],
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'tenant_id': tenantId,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'access_token': accessToken,
      'token_type': tokenType,
      'scopes': scopes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Global routing record schema: whatsapp_routing/{phoneNumberId}
class GlobalRoutingRecordContract {
  final String phoneNumberId;
  final String wabaId;
  final String tenantId;
  final bool active;
  final DateTime updatedAt;

  const GlobalRoutingRecordContract({
    required this.phoneNumberId,
    required this.wabaId,
    required this.tenantId,
    this.active = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'phone_number_id': phoneNumberId,
      'waba_id': wabaId,
      'tenant_id': tenantId,
      'active': active,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
