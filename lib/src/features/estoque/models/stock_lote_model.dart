import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um Lote específico de um item de estoque.
/// Garante rastreabilidade estrita (FIFO/PEPS), datas de fabricação e validade física.
class StockLoteModel {
  final String id;
  final String tenantId;
  final String itemId;
  final String loteCodigo;
  final DateTime? dataFabricacao;
  final DateTime? dataValidade;
  final double qtdInicial;
  final double qtdAtual;
  final double precoAquisicao;
  final String? fornecedor;
  final String status; // ATIVO, ESGOTADO, VENCIDO, BLOQUEADO
  final DateTime? criadoEm;

  StockLoteModel({
    required this.id,
    required this.tenantId,
    required this.itemId,
    required this.loteCodigo,
    this.dataFabricacao,
    this.dataValidade,
    required this.qtdInicial,
    required this.qtdAtual,
    this.precoAquisicao = 0.0,
    this.fornecedor,
    this.status = 'ATIVO',
    this.criadoEm,
  });

  bool get isVencido =>
      dataValidade != null && dataValidade!.isBefore(DateTime.now());

  bool get isPertoVencer {
    if (dataValidade == null || isVencido) return false;
    final diff = dataValidade!.difference(DateTime.now()).inDays;
    return diff <= 30;
  }

  int? get diasParaVencer => dataValidade?.difference(DateTime.now()).inDays;

  factory StockLoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockLoteModel.fromMap(data, doc.id);
  }

  factory StockLoteModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    return StockLoteModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      itemId: map['item_id'] ?? '',
      loteCodigo: map['lote_codigo'] ?? '',
      dataFabricacao: parseDate(map['data_fabricacao']),
      dataValidade: parseDate(map['data_validade']),
      qtdInicial: (map['qtd_inicial'] ?? 0.0).toDouble(),
      qtdAtual: (map['qtd_atual'] ?? 0.0).toDouble(),
      precoAquisicao: (map['preco_aquisicao'] ?? 0.0).toDouble(),
      fornecedor: map['fornecedor'],
      status: map['status'] ?? 'ATIVO',
      criadoEm: parseDate(map['criado_em']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'item_id': itemId,
      'lote_codigo': loteCodigo,
      'data_fabricacao':
          dataFabricacao != null ? Timestamp.fromDate(dataFabricacao!) : null,
      'data_validade':
          dataValidade != null ? Timestamp.fromDate(dataValidade!) : null,
      'qtd_inicial': qtdInicial,
      'qtd_atual': qtdAtual,
      'preco_aquisicao': precoAquisicao,
      'fornecedor': fornecedor,
      'status': isVencido && status == 'ATIVO' ? 'VENCIDO' : status,
      'criado_em': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : Timestamp.now(),
    };
  }

  StockLoteModel copyWith({
    String? id,
    String? tenantId,
    String? itemId,
    String? loteCodigo,
    DateTime? dataFabricacao,
    DateTime? dataValidade,
    double? qtdInicial,
    double? qtdAtual,
    double? precoAquisicao,
    String? fornecedor,
    String? status,
    DateTime? criadoEm,
  }) {
    return StockLoteModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      itemId: itemId ?? this.itemId,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      dataFabricacao: dataFabricacao ?? this.dataFabricacao,
      dataValidade: dataValidade ?? this.dataValidade,
      qtdInicial: qtdInicial ?? this.qtdInicial,
      qtdAtual: qtdAtual ?? this.qtdAtual,
      precoAquisicao: precoAquisicao ?? this.precoAquisicao,
      fornecedor: fornecedor ?? this.fornecedor,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
