import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Auditoria e Movimentação de Estoque.
/// Registra entradas, saídas, perdas e transferências de lotes.
class StockMovimentacaoModel {
  final String id;
  final String tenantId;
  final String itemId;
  final String nomeProduto;
  final String sku;
  final String tipo; // ENTRADA, SAIDA_VENDA, SAIDA_EPI, AJUSTE_POSITIVO, AJUSTE_NEGATIVO, PERDA, DEVOLUCAO
  final double quantidade;
  final double saldoAnterior;
  final double saldoPosterior;
  final String? loteCodigo;
  final String motivo;
  final String? usuarioUid;
  final String? usuarioNome;
  final DateTime timestamp;

  StockMovimentacaoModel({
    required this.id,
    required this.tenantId,
    required this.itemId,
    required this.nomeProduto,
    required this.sku,
    required this.tipo,
    required this.quantidade,
    required this.saldoAnterior,
    required this.saldoPosterior,
    this.loteCodigo,
    required this.motivo,
    this.usuarioUid,
    this.usuarioNome,
    required this.timestamp,
  });

  bool get isEntrada =>
      tipo == 'ENTRADA' || tipo == 'AJUSTE_POSITIVO' || tipo == 'DEVOLUCAO';

  factory StockMovimentacaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockMovimentacaoModel.fromMap(data, doc.id);
  }

  factory StockMovimentacaoModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return StockMovimentacaoModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      itemId: map['item_id'] ?? '',
      nomeProduto: map['nome_produto'] ?? '',
      sku: map['sku'] ?? '',
      tipo: map['tipo'] ?? 'ENTRADA',
      quantidade: (map['quantidade'] ?? 0.0).toDouble(),
      saldoAnterior: (map['saldo_anterior'] ?? 0.0).toDouble(),
      saldoPosterior: (map['saldo_posterior'] ?? 0.0).toDouble(),
      loteCodigo: map['lote_codigo'],
      motivo: map['motivo'] ?? '',
      usuarioUid: map['usuario_uid'],
      usuarioNome: map['usuario_nome'],
      timestamp: parseDate(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'item_id': itemId,
      'nome_produto': nomeProduto,
      'sku': sku,
      'tipo': tipo,
      'quantidade': quantidade,
      'saldo_anterior': saldoAnterior,
      'saldo_posterior': saldoPosterior,
      'lote_codigo': loteCodigo,
      'motivo': motivo,
      'usuario_uid': usuarioUid,
      'usuario_nome': usuarioNome,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
