import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo completo e de classe mundial para Item de Estoque (SaaS Multitenant).
/// Especializado em conformidade NR-06 (EPIs), Certificados de Aprovação (CA)
/// e rastreabilidade temporal.
class StockItemModel {
  final String id;
  final String tenantId;
  final String nomeProduto;
  final String sku;
  final String? codigoBarrasEan;
  final String categoria;
  final double qtdAtual;
  final String unidadeMedida;
  final double precoVenda;
  final double precoCusto;
  final double nivelAlerta;
  final double estoqueMinimo;
  final String? localizacao;
  final bool isEpi;
  final String? caNumero;
  final DateTime? caValidade;
  final String caSituacao; // VALIDO, VENCIDO, EM_RENOVACAO, NAO_APLICAVEL
  final List<String> normasAtendidas;
  final int? diasVidaUtilUso; // Dias de vida útil após entrega/uso
  final String? fabricante;
  final String? tipoProtecao; // Mãos, Olhos, Auditiva, Cabeça, etc.
  final bool ativo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  StockItemModel({
    required this.id,
    required this.tenantId,
    required this.nomeProduto,
    required this.sku,
    this.codigoBarrasEan,
    this.categoria = 'Geral',
    required this.qtdAtual,
    required this.unidadeMedida,
    required this.precoVenda,
    this.precoCusto = 0.0,
    required this.nivelAlerta,
    this.estoqueMinimo = 0.0,
    this.localizacao,
    this.isEpi = false,
    this.caNumero,
    this.caValidade,
    this.caSituacao = 'VALIDO',
    this.normasAtendidas = const [],
    this.diasVidaUtilUso,
    this.fabricante,
    this.tipoProtecao,
    this.ativo = true,
    this.criadoEm,
    this.atualizadoEm,
  });

  /// Getters semânticos de saúde de estoque e conformidade
  bool get isAlerta => qtdAtual <= nivelAlerta;
  bool get isRuptura => qtdAtual <= 0;
  bool get isCaVencido =>
      isEpi && caValidade != null && caValidade!.isBefore(DateTime.now());
  bool get isCaPertoVencer {
    if (!isEpi || caValidade == null || isCaVencido) return false;
    final diff = caValidade!.difference(DateTime.now()).inDays;
    return diff <= 60;
  }

  /// Converte um DocumentSnapshot do Firestore para StockItemModel.
  factory StockItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockItemModel.fromMap(data, doc.id);
  }

  /// Converte um Map para StockItemModel garantindo retrocompatibilidade total.
  factory StockItemModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    final epiInfo = (map['epi_info'] as Map<String, dynamic>?) ?? {};

    return StockItemModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      nomeProduto: map['nome_produto'] ?? '',
      sku: map['sku'] ?? '',
      codigoBarrasEan: map['codigo_barras_ean'] ?? map['ean'],
      categoria: map['categoria'] ?? 'Geral',
      qtdAtual: (map['qtd_atual'] ?? 0.0).toDouble(),
      unidadeMedida: map['unidade_medida'] ?? 'UN',
      precoVenda: (map['preco_venda'] ?? 0.0).toDouble(),
      precoCusto: (map['preco_custo'] ?? 0.0).toDouble(),
      nivelAlerta: (map['nivel_alerta'] ?? 0.0).toDouble(),
      estoqueMinimo: (map['estoque_minimo'] ?? map['nivel_alerta'] ?? 0.0).toDouble(),
      localizacao: map['localizacao_almoxarifado'] ?? map['localizacao'],
      isEpi: map['is_epi'] ?? (epiInfo.isNotEmpty),
      caNumero: map['ca_numero'] ?? epiInfo['ca_numero'],
      caValidade: parseDate(map['ca_validade'] ?? epiInfo['ca_validade']),
      caSituacao: map['ca_situacao'] ?? epiInfo['ca_situacao'] ?? 'VALIDO',
      normasAtendidas: List<String>.from(
          map['normas_atendidas'] ?? epiInfo['normas_atendidas'] ?? []),
      diasVidaUtilUso: (map['dias_vida_util_uso'] ?? epiInfo['dias_vida_util_uso']) as int?,
      fabricante: map['fabricante'] ?? epiInfo['fabricante'],
      tipoProtecao: map['tipo_protecao'] ?? epiInfo['tipo_protecao'],
      ativo: map['ativo'] ?? true,
      criadoEm: parseDate(map['criado_em']),
      atualizadoEm: parseDate(map['atualizado_em']),
    );
  }

  /// Converte para Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'nome_produto': nomeProduto,
      'sku': sku,
      'codigo_barras_ean': codigoBarrasEan,
      'categoria': categoria,
      'qtd_atual': qtdAtual,
      'unidade_medida': unidadeMedida,
      'preco_venda': precoVenda,
      'preco_custo': precoCusto,
      'nivel_alerta': nivelAlerta,
      'estoque_minimo': estoqueMinimo,
      'localizacao_almoxarifado': localizacao,
      'is_epi': isEpi,
      'ca_numero': caNumero,
      'ca_validade': caValidade != null ? Timestamp.fromDate(caValidade!) : null,
      'ca_situacao': caSituacao,
      'normas_atendidas': normasAtendidas,
      'dias_vida_util_uso': diasVidaUtilUso,
      'fabricante': fabricante,
      'tipo_protecao': tipoProtecao,
      'epi_info': isEpi
          ? {
              'ca_numero': caNumero,
              'ca_validade':
                  caValidade != null ? Timestamp.fromDate(caValidade!) : null,
              'ca_situacao': caSituacao,
              'normas_atendidas': normasAtendidas,
              'dias_vida_util_uso': diasVidaUtilUso,
              'fabricante': fabricante,
              'tipo_protecao': tipoProtecao,
            }
          : null,
      'ativo': ativo,
      'atualizado_em': Timestamp.now(),
    };
  }

  StockItemModel copyWith({
    String? id,
    String? tenantId,
    String? nomeProduto,
    String? sku,
    String? codigoBarrasEan,
    String? categoria,
    double? qtdAtual,
    String? unidadeMedida,
    double? precoVenda,
    double? precoCusto,
    double? nivelAlerta,
    double? estoqueMinimo,
    String? localizacao,
    bool? isEpi,
    String? caNumero,
    DateTime? caValidade,
    String? caSituacao,
    List<String>? normasAtendidas,
    int? diasVidaUtilUso,
    String? fabricante,
    String? tipoProtecao,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      sku: sku ?? this.sku,
      codigoBarrasEan: codigoBarrasEan ?? this.codigoBarrasEan,
      categoria: categoria ?? this.categoria,
      qtdAtual: qtdAtual ?? this.qtdAtual,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      precoVenda: precoVenda ?? this.precoVenda,
      precoCusto: precoCusto ?? this.precoCusto,
      nivelAlerta: nivelAlerta ?? this.nivelAlerta,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      localizacao: localizacao ?? this.localizacao,
      isEpi: isEpi ?? this.isEpi,
      caNumero: caNumero ?? this.caNumero,
      caValidade: caValidade ?? this.caValidade,
      caSituacao: caSituacao ?? this.caSituacao,
      normasAtendidas: normasAtendidas ?? this.normasAtendidas,
      diasVidaUtilUso: diasVidaUtilUso ?? this.diasVidaUtilUso,
      fabricante: fabricante ?? this.fabricante,
      tipoProtecao: tipoProtecao ?? this.tipoProtecao,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
