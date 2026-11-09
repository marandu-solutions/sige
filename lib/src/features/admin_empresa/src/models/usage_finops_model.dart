import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// FinOps metrics tracking AI processing consumption (LLM tokens, audio, vision).
/// Reference: MD07 §4.4, PROJECT.md Feature #17
class IaMetrics {
  /// Total automated request cycles processed by the AI
  final int totalRequests;

  /// Prompt input tokens consumed
  final int tokensInput;

  /// Completion output tokens generated
  final int tokensOutput;

  /// Total minutes of audio transcribed via Whisper / STT
  final int audiosTranscritosMinutos;

  /// Total PDF/image documents parsed via vision or OCR
  final int documentosAnalisados;

  /// Cumulative cost in Brazilian Reais (BRL)
  final double custoAcumuladoBrl;

  /// Estimated human hours saved through automated AI resolution
  final double economiaEstimadaHorasHumanas;

  const IaMetrics({
    this.totalRequests = 0,
    this.tokensInput = 0,
    this.tokensOutput = 0,
    this.audiosTranscritosMinutos = 0,
    this.documentosAnalisados = 0,
    this.custoAcumuladoBrl = 0.0,
    this.economiaEstimadaHorasHumanas = 0.0,
  });

  /// Total tokens (Input + Output)
  int get totalTokens => tokensInput + tokensOutput;

  /// Average cost per AI request
  double get custoMedioPorRequest =>
      totalRequests > 0 ? custoAcumuladoBrl / totalRequests : 0.0;

  /// Formatted tokens representation (e.g. `2,47M` or `18.500`)
  String get totalTokensFormatado {
    if (totalTokens >= 1000000) {
      return '${(totalTokens / 1000000.0).toStringAsFixed(2).replaceAll('.', ',')}M';
    }
    if (totalTokens >= 1000) {
      return '${(totalTokens / 1000.0).toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return totalTokens.toString();
  }

  /// Formatted cost in BRL
  String get custoFormatadoBrl =>
      'R\$ ${custoAcumuladoBrl.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Deserializer handling null maps and numeric conversions
  factory IaMetrics.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const IaMetrics();
    return IaMetrics(
      totalRequests:
          (data['total_requests'] ?? data['totalRequests'] as num?)?.toInt() ?? 0,
      tokensInput:
          (data['tokens_input'] ?? data['tokensInput'] as num?)?.toInt() ?? 0,
      tokensOutput:
          (data['tokens_output'] ?? data['tokensOutput'] as num?)?.toInt() ?? 0,
      audiosTranscritosMinutos: (data['audios_transcritos_minutos'] ??
              data['audiosTranscritosMinutos'] as num?)
          ?.toInt() ??
          0,
      documentosAnalisados: (data['documentos_analisados'] ??
              data['documentosAnalisados'] as num?)
          ?.toInt() ??
          0,
      custoAcumuladoBrl: (data['custo_acumulado_brl'] ??
              data['custoAcumuladoBrl'] as num?)
          ?.toDouble() ??
          0.0,
      economiaEstimadaHorasHumanas: (data['economia_estimada_horas_humanas'] ??
              data['economiaEstimadaHorasHumanas'] as num?)
          ?.toDouble() ??
          0.0,
    );
  }

  /// Serializer to Firestore-compliant map
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

  IaMetrics copyWith({
    int? totalRequests,
    int? tokensInput,
    int? tokensOutput,
    int? audiosTranscritosMinutos,
    int? documentosAnalisados,
    double? custoAcumuladoBrl,
    double? economiaEstimadaHorasHumanas,
  }) {
    return IaMetrics(
      totalRequests: totalRequests ?? this.totalRequests,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      audiosTranscritosMinutos:
          audiosTranscritosMinutos ?? this.audiosTranscritosMinutos,
      documentosAnalisados: documentosAnalisados ?? this.documentosAnalisados,
      custoAcumuladoBrl: custoAcumuladoBrl ?? this.custoAcumuladoBrl,
      economiaEstimadaHorasHumanas:
          economiaEstimadaHorasHumanas ?? this.economiaEstimadaHorasHumanas,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IaMetrics &&
        other.totalRequests == totalRequests &&
        other.tokensInput == tokensInput &&
        other.tokensOutput == tokensOutput &&
        other.audiosTranscritosMinutos == audiosTranscritosMinutos &&
        other.documentosAnalisados == documentosAnalisados &&
        (other.custoAcumuladoBrl - custoAcumuladoBrl).abs() < 0.0001 &&
        (other.economiaEstimadaHorasHumanas - economiaEstimadaHorasHumanas).abs() <
            0.0001;
  }

  @override
  int get hashCode => Object.hash(
        totalRequests,
        tokensInput,
        tokensOutput,
        audiosTranscritosMinutos,
        documentosAnalisados,
        custoAcumuladoBrl,
        economiaEstimadaHorasHumanas,
      );

  @override
  String toString() {
    return 'IaMetrics(requests: $totalRequests, tokens: $totalTokens, custo: $custoFormatadoBrl)';
  }
}

/// FinOps metrics tracking official Meta WhatsApp Cloud API conversations.
/// Reference: MD07 §4.4, PROJECT.md Feature #17
class WhatsAppMetrics {
  /// Total conversations initiated or received in the billing period
  final int totalConversas;

  /// User-initiated service conversations within free 24-hour service tier
  final int conversasServicoGratuitas;

  /// Business-initiated utility/transactional templates (orders, receipts)
  final int conversasUtilidade;

  /// Business-initiated marketing templates (promotions, offers)
  final int conversasMarketing;

  /// Business-initiated authentication/OTP templates
  final int conversasAutenticacao;

  /// Cumulative cost charged by Meta in Brazilian Reais (BRL)
  final double custoAcumuladoBrl;

  const WhatsAppMetrics({
    this.totalConversas = 0,
    this.conversasServicoGratuitas = 0,
    this.conversasUtilidade = 0,
    this.conversasMarketing = 0,
    this.conversasAutenticacao = 0,
    this.custoAcumuladoBrl = 0.0,
  });

  /// Total billable paid conversations (Utility + Marketing + Authentication)
  int get conversasPagas =>
      conversasUtilidade + conversasMarketing + conversasAutenticacao;

  /// Percentage of conversations that were 100% free
  double get percentualGratuitas =>
      totalConversas > 0 ? (conversasServicoGratuitas / totalConversas) * 100.0 : 0.0;

  /// Formatted cost in BRL
  String get custoFormatadoBrl =>
      'R\$ ${custoAcumuladoBrl.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Deserializer handling null maps and numeric conversions
  factory WhatsAppMetrics.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const WhatsAppMetrics();
    return WhatsAppMetrics(
      totalConversas:
          (data['total_conversas'] ?? data['totalConversas'] as num?)?.toInt() ?? 0,
      conversasServicoGratuitas: (data['conversas_servico_gratuitas'] ??
              data['conversasServicoGratuitas'] as num?)
          ?.toInt() ??
          0,
      conversasUtilidade: (data['conversas_utilidade'] ??
              data['conversasUtilidade'] as num?)
          ?.toInt() ??
          0,
      conversasMarketing: (data['conversas_marketing'] ??
              data['conversasMarketing'] as num?)
          ?.toInt() ??
          0,
      conversasAutenticacao: (data['conversas_autenticacao'] ??
              data['conversasAutenticacao'] as num?)
          ?.toInt() ??
          0,
      custoAcumuladoBrl: (data['custo_acumulado_brl'] ??
              data['custoAcumuladoBrl'] as num?)
          ?.toDouble() ??
          0.0,
    );
  }

  /// Serializer to Firestore-compliant map
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

  WhatsAppMetrics copyWith({
    int? totalConversas,
    int? conversasServicoGratuitas,
    int? conversasUtilidade,
    int? conversasMarketing,
    int? conversasAutenticacao,
    double? custoAcumuladoBrl,
  }) {
    return WhatsAppMetrics(
      totalConversas: totalConversas ?? this.totalConversas,
      conversasServicoGratuitas:
          conversasServicoGratuitas ?? this.conversasServicoGratuitas,
      conversasUtilidade: conversasUtilidade ?? this.conversasUtilidade,
      conversasMarketing: conversasMarketing ?? this.conversasMarketing,
      conversasAutenticacao: conversasAutenticacao ?? this.conversasAutenticacao,
      custoAcumuladoBrl: custoAcumuladoBrl ?? this.custoAcumuladoBrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsAppMetrics &&
        other.totalConversas == totalConversas &&
        other.conversasServicoGratuitas == conversasServicoGratuitas &&
        other.conversasUtilidade == conversasUtilidade &&
        other.conversasMarketing == conversasMarketing &&
        other.conversasAutenticacao == conversasAutenticacao &&
        (other.custoAcumuladoBrl - custoAcumuladoBrl).abs() < 0.0001;
  }

  @override
  int get hashCode => Object.hash(
        totalConversas,
        conversasServicoGratuitas,
        conversasUtilidade,
        conversasMarketing,
        conversasAutenticacao,
        custoAcumuladoBrl,
      );

  @override
  String toString() {
    return 'WhatsAppMetrics(total: $totalConversas, pagas: $conversasPagas, custo: $custoFormatadoBrl)';
  }
}

/// Daily cost telemetry entry in [UsageFinopsModel.historicoDiario].
/// Used to plot charts (`fl_chart`) in the executive cockpit.
class HistoricoDiarioItem {
  /// Day of month (1 to 31)
  final int dia;

  /// Daily AI expenditure in BRL
  final double custoIa;

  /// Daily WhatsApp Meta expenditure in BRL
  final double custoWa;

  /// Total message interaction count processed on this day
  final int msgs;

  const HistoricoDiarioItem({
    required this.dia,
    required this.custoIa,
    required this.custoWa,
    required this.msgs,
  });

  /// Combined daily investment (AI + WhatsApp)
  double get custoTotal => custoIa + custoWa;

  /// Formatted total daily cost in BRL
  String get custoTotalFormatado =>
      'R\$ ${custoTotal.toStringAsFixed(2).replaceAll('.', ',')}';

  factory HistoricoDiarioItem.fromMap(Map<String, dynamic> data) {
    return HistoricoDiarioItem(
      dia: (data['dia'] as num?)?.toInt() ?? 1,
      custoIa: (data['custo_ia'] ?? data['custoIa'] as num?)?.toDouble() ?? 0.0,
      custoWa: (data['custo_wa'] ?? data['custoWa'] as num?)?.toDouble() ?? 0.0,
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

  HistoricoDiarioItem copyWith({
    int? dia,
    double? custoIa,
    double? custoWa,
    int? msgs,
  }) {
    return HistoricoDiarioItem(
      dia: dia ?? this.dia,
      custoIa: custoIa ?? this.custoIa,
      custoWa: custoWa ?? this.custoWa,
      msgs: msgs ?? this.msgs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoricoDiarioItem &&
        other.dia == dia &&
        (other.custoIa - custoIa).abs() < 0.0001 &&
        (other.custoWa - custoWa).abs() < 0.0001 &&
        other.msgs == msgs;
  }

  @override
  int get hashCode => Object.hash(dia, custoIa, custoWa, msgs);

  @override
  String toString() {
    return 'HistoricoDiarioItem(dia: $dia, ia: $custoIa, wa: $custoWa, msgs: $msgs)';
  }
}

/// Alias for [HistoricoDiarioItem] for compatibility with test suites
typedef DailyUsageContract = HistoricoDiarioItem;

/// Executive FinOps health category indicator
enum FinopsHealthStatus {
  healthy,
  warning,
  exceeded;

  String get label {
    switch (this) {
      case FinopsHealthStatus.healthy:
        return 'Dentro da meta mensal';
      case FinopsHealthStatus.warning:
        return 'Atenção: Limite de alerta atingido';
      case FinopsHealthStatus.exceeded:
        return 'Orçamento mensal estourado';
    }
  }

  Color get color {
    switch (this) {
      case FinopsHealthStatus.healthy:
        return const Color(0xFF16A34A); // Green-600
      case FinopsHealthStatus.warning:
        return const Color(0xFFCA8A04); // Yellow-600
      case FinopsHealthStatus.exceeded:
        return const Color(0xFFDC2626); // Red-600
    }
  }
}

/// Monthly FinOps Telemetry Rollup Document (`tenant/{tenantId}/usage_metrics/{YYYY_MM}`).
///
/// Designed for maximum performance: enables reading all monthly metrics, category breakdowns,
/// and daily timeline points in a single O(1) Firestore Document Read.
/// Reference: MD07 §4.4, PROJECT.md Feature #17
class UsageFinopsModel {
  /// Month identifier in `YYYY_MM` format (e.g. `2026_11`)
  final String competencia;

  /// Tenant owning this usage rollup
  final String tenantId;

  /// Monthly financial budget cap in BRL set by the executive (default R$ 1.000,00)
  final double orcamentoMensalBrl;

  /// Warning threshold percentage (default 80.0%)
  final double alertaOrcamentoPercentual;

  /// Granular AI motor metrics
  final IaMetrics iaMetrics;

  /// Granular Meta WhatsApp Cloud API messaging metrics
  final WhatsAppMetrics whatsappMetrics;

  /// Daily cost trajectory for trend chart visualization
  final List<HistoricoDiarioItem> historicoDiario;

  /// Timestamp when telemetry was last rolled up by backend
  final DateTime updatedAt;

  const UsageFinopsModel({
    required this.competencia,
    required this.tenantId,
    this.orcamentoMensalBrl = 1000.0,
    this.alertaOrcamentoPercentual = 80.0,
    this.iaMetrics = const IaMetrics(),
    this.whatsappMetrics = const WhatsAppMetrics(),
    this.historicoDiario = const [],
    required this.updatedAt,
  });

  /// Total combined investment in BRL (AI + WhatsApp)
  double get custoTotalAcumuladoBrl =>
      iaMetrics.custoAcumuladoBrl + whatsappMetrics.custoAcumuladoBrl;

  /// Alias matching contract test fixture
  double get totalInvestimentoBrl => custoTotalAcumuladoBrl;

  /// Percentage of monthly budget consumed (guarded against division by zero)
  double get percentualOrcamentoConsumido {
    if (orcamentoMensalBrl <= 0.0) return 0.0;
    return (custoTotalAcumuladoBrl / orcamentoMensalBrl) * 100.0;
  }

  /// Alias matching contract test fixture
  double get percentualConsumido => percentualOrcamentoConsumido;

  /// Remaining financial budget balance in BRL (negative if exceeded)
  double get saldoOrcamentoBrl {
    if (orcamentoMensalBrl <= 0.0) return 0.0;
    return orcamentoMensalBrl - custoTotalAcumuladoBrl;
  }

  /// Alias matching contract test fixture
  double get saldoRestanteBrl => saldoOrcamentoBrl;

  /// True if consumed percentage meets or exceeds [alertaOrcamentoPercentual]
  bool get isAlertaOrcamentoAtingido =>
      percentualOrcamentoConsumido >= alertaOrcamentoPercentual;

  /// Alias matching contract test fixture
  bool get isAlertThresholdReached => isAlertaOrcamentoAtingido;

  /// True if total consumption exceeds the total authorized budget
  bool get isOrcamentoEstourado =>
      orcamentoMensalBrl > 0.0 && custoTotalAcumuladoBrl > orcamentoMensalBrl;

  /// Alias matching contract test fixture
  bool get isBudgetExceeded => isOrcamentoEstourado;

  /// Overall budget health status classification
  FinopsHealthStatus get healthStatus {
    if (isOrcamentoEstourado) return FinopsHealthStatus.exceeded;
    if (isAlertaOrcamentoAtingido) return FinopsHealthStatus.warning;
    return FinopsHealthStatus.healthy;
  }

  /// Formatted total investment string in BRL
  String get custoTotalFormatadoBrl =>
      'R\$ ${custoTotalAcumuladoBrl.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Formatted remaining balance string in BRL
  String get saldoRestanteFormatadoBrl =>
      'R\$ ${saldoOrcamentoBrl.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Formatted monthly budget string in BRL
  String get orcamentoFormatadoBrl =>
      'R\$ ${orcamentoMensalBrl.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Human-friendly month description (e.g. `Novembro/2026`)
  String get competenciaFormatada {
    final parts = competencia.split('_');
    if (parts.length != 2) return competencia;
    final year = parts[0];
    final month = switch (parts[1]) {
      '01' => 'Janeiro',
      '02' => 'Fevereiro',
      '03' => 'Março',
      '04' => 'Abril',
      '05' => 'Maio',
      '06' => 'Junho',
      '07' => 'Julho',
      '08' => 'Agosto',
      '09' => 'Setembro',
      '10' => 'Outubro',
      '11' => 'Novembro',
      '12' => 'Dezembro',
      _ => parts[1],
    };
    return '$month/$year';
  }

  /// Fallback instance for new tenants or periods when no document exists yet
  factory UsageFinopsModel.zeroState({
    required String tenantId,
    required String competencia,
    double orcamentoMensalBrl = 1000.0,
    double alertaOrcamentoPercentual = 80.0,
  }) {
    return UsageFinopsModel(
      competencia: competencia,
      tenantId: tenantId,
      orcamentoMensalBrl: orcamentoMensalBrl,
      alertaOrcamentoPercentual: alertaOrcamentoPercentual,
      iaMetrics: const IaMetrics(),
      whatsappMetrics: const WhatsAppMetrics(),
      historicoDiario: const [],
      updatedAt: DateTime.now(),
    );
  }

  /// Helper to parse multiple date representations (Timestamp, DateTime, String, int)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// Deserializer from Map (handles snake_case and camelCase)
  factory UsageFinopsModel.fromMap(
    Map<String, dynamic> data, [
    String? docCompetencia,
  ]) {
    final effectiveCompetencia = docCompetencia ??
        data['competencia'] as String? ??
        data['id'] as String? ??
        '';

    final rawHistorico = data['historico_diario'] ?? data['historicoDiario'];
    List<HistoricoDiarioItem> historico = const [];
    if (rawHistorico is List) {
      historico = rawHistorico
          .whereType<Map>()
          .map((item) => HistoricoDiarioItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return UsageFinopsModel(
      competencia: effectiveCompetencia,
      tenantId: data['tenant_id'] as String? ?? data['tenantId'] as String? ?? '',
      orcamentoMensalBrl:
          (data['orcamento_mensal_brl'] ?? data['orcamentoMensalBrl'] as num?)
                  ?.toDouble() ??
              1000.0,
      alertaOrcamentoPercentual: (data['alerta_orcamento_percentual'] ??
                  data['alertaOrcamentoPercentual'] as num?)
              ?.toDouble() ??
          80.0,
      iaMetrics: IaMetrics.fromMap(
        data['ia_metrics'] as Map<String, dynamic>? ??
            data['iaMetrics'] as Map<String, dynamic>?,
      ),
      whatsappMetrics: WhatsAppMetrics.fromMap(
        data['whatsapp_metrics'] as Map<String, dynamic>? ??
            data['whatsappMetrics'] as Map<String, dynamic>?,
      ),
      historicoDiario: historico,
      updatedAt: _parseDateTime(data['updated_at'] ?? data['updatedAt']),
    );
  }

  /// Deserializer for Firestore DocumentSnapshot
  factory UsageFinopsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UsageFinopsModel.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Deserializer for contract/fixture compatibility
  factory UsageFinopsModel.fromFirestoreMap(
    String competencia,
    Map<String, dynamic> data,
  ) {
    return UsageFinopsModel.fromMap(data, competencia);
  }

  /// Serializer to Firestore-compliant map with snake_case keys
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'competencia': competencia,
      'tenant_id': tenantId,
      'orcamento_mensal_brl': orcamentoMensalBrl,
      'alerta_orcamento_percentual': alertaOrcamentoPercentual,
      'ia_metrics': iaMetrics.toMap(),
      'whatsapp_metrics': whatsappMetrics.toMap(),
      'historico_diario': historicoDiario.map((e) => e.toMap()).toList(),
      'updated_at': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
  }

  /// Serialization to primitive map for tests and JSON serialization
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

  UsageFinopsModel copyWith({
    String? competencia,
    String? tenantId,
    double? orcamentoMensalBrl,
    double? alertaOrcamentoPercentual,
    IaMetrics? iaMetrics,
    WhatsAppMetrics? whatsappMetrics,
    List<HistoricoDiarioItem>? historicoDiario,
    DateTime? updatedAt,
  }) {
    return UsageFinopsModel(
      competencia: competencia ?? this.competencia,
      tenantId: tenantId ?? this.tenantId,
      orcamentoMensalBrl: orcamentoMensalBrl ?? this.orcamentoMensalBrl,
      alertaOrcamentoPercentual:
          alertaOrcamentoPercentual ?? this.alertaOrcamentoPercentual,
      iaMetrics: iaMetrics ?? this.iaMetrics,
      whatsappMetrics: whatsappMetrics ?? this.whatsappMetrics,
      historicoDiario: historicoDiario ?? this.historicoDiario,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageFinopsModel &&
        other.competencia == competencia &&
        other.tenantId == tenantId &&
        (other.orcamentoMensalBrl - orcamentoMensalBrl).abs() < 0.0001 &&
        (other.alertaOrcamentoPercentual - alertaOrcamentoPercentual).abs() < 0.0001 &&
        other.iaMetrics == iaMetrics &&
        other.whatsappMetrics == whatsappMetrics &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        competencia,
        tenantId,
        orcamentoMensalBrl,
        alertaOrcamentoPercentual,
        iaMetrics,
        whatsappMetrics,
        updatedAt,
      );

  @override
  String toString() {
    return 'UsageFinopsModel(competencia: $competencia, total: $custoTotalFormatadoBrl, orcamento: $orcamentoFormatadoBrl, pct: ${percentualOrcamentoConsumido.toStringAsFixed(1)}%)';
  }
}

/// Compatibility typedef matching contract nomenclature in test suites
typedef FinOpsUsageModelContract = UsageFinopsModel;
typedef IaMetricsContract = IaMetrics;
typedef WhatsAppMetricsContract = WhatsAppMetrics;
