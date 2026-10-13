import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um item de estoque.
/// Contém tenantId para garantir isolamento de dados entre empresas.
class StockItemModel {
  final String id;
  final String tenantId;
  final String nomeProduto;
  final String sku;
  final double qtdAtual;
  final String unidadeMedida;
  final double precoVenda;
  final double nivelAlerta;

  StockItemModel({
    required this.id,
    required this.tenantId,
    required this.nomeProduto,
    required this.sku,
    required this.qtdAtual,
    required this.unidadeMedida,
    required this.precoVenda,
    required this.nivelAlerta,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto StockItemModel.
  factory StockItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockItemModel.fromMap(data, doc.id);
  }

  /// Converte um Map para StockItemModel
  factory StockItemModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return StockItemModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      nomeProduto: map['nome_produto'] ?? '',
      sku: map['sku'] ?? '',
      qtdAtual: (map['qtd_atual'] ?? 0.0).toDouble(),
      unidadeMedida: map['unidade_medida'] ?? 'UN',
      precoVenda: (map['preco_venda'] ?? 0.0).toDouble(),
      nivelAlerta: (map['nivel_alerta'] ?? 0.0).toDouble(),
    );
  }

  /// Converte o objeto StockItemModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'nome_produto': nomeProduto,
      'sku': sku,
      'qtd_atual': qtdAtual,
      'unidade_medida': unidadeMedida,
      'preco_venda': precoVenda,
      'nivel_alerta': nivelAlerta,
    };
  }

  /// Retorna uma cópia do item com os dados atualizados.
  StockItemModel copyWith({
    String? id,
    String? tenantId,
    String? nomeProduto,
    String? sku,
    double? qtdAtual,
    String? unidadeMedida,
    double? precoVenda,
    double? nivelAlerta,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      sku: sku ?? this.sku,
      qtdAtual: qtdAtual ?? this.qtdAtual,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      precoVenda: precoVenda ?? this.precoVenda,
      nivelAlerta: nivelAlerta ?? this.nivelAlerta,
    );
  }

  @override
  String toString() {
    return 'StockItemModel(id: $id, nomeProduto: $nomeProduto, sku: $sku, qtdAtual: $qtdAtual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockItemModel &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.nomeProduto == nomeProduto &&
        other.sku == sku &&
        other.qtdAtual == qtdAtual &&
        other.unidadeMedida == unidadeMedida &&
        other.precoVenda == precoVenda &&
        other.nivelAlerta == nivelAlerta;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tenantId.hashCode ^
        nomeProduto.hashCode ^
        sku.hashCode ^
        qtdAtual.hashCode ^
        unidadeMedida.hashCode ^
        precoVenda.hashCode ^
        nivelAlerta.hashCode;
  }
}
