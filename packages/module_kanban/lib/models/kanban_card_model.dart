import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um card no Kanban.
/// Contém tenantId para garantir isolamento de dados entre empresas.
class KanbanCardModel {
  final String id;
  final String tenantId;
  final String titulo;
  final String colunaStatus;
  final String prioridade;
  final DateTime dataLimite;

  KanbanCardModel({
    required this.id,
    required this.tenantId,
    required this.titulo,
    required this.colunaStatus,
    required this.prioridade,
    required this.dataLimite,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto KanbanCardModel.
  factory KanbanCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KanbanCardModel.fromMap(data, doc.id);
  }

  /// Converte um Map para KanbanCardModel
  factory KanbanCardModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return KanbanCardModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      titulo: map['titulo'] ?? '',
      colunaStatus: map['coluna_status'] ?? 'to_do',
      prioridade: map['prioridade'] ?? 'media',
      dataLimite: (map['data_limite'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converte o objeto KanbanCardModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'titulo': titulo,
      'coluna_status': colunaStatus,
      'prioridade': prioridade,
      'data_limite': Timestamp.fromDate(dataLimite),
    };
  }

  /// Retorna uma cópia do card com os dados atualizados.
  KanbanCardModel copyWith({
    String? id,
    String? tenantId,
    String? titulo,
    String? colunaStatus,
    String? prioridade,
    DateTime? dataLimite,
  }) {
    return KanbanCardModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      titulo: titulo ?? this.titulo,
      colunaStatus: colunaStatus ?? this.colunaStatus,
      prioridade: prioridade ?? this.prioridade,
      dataLimite: dataLimite ?? this.dataLimite,
    );
  }

  @override
  String toString() {
    return 'KanbanCardModel(id: $id, titulo: $titulo, colunaStatus: $colunaStatus, prioridade: $prioridade)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KanbanCardModel &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.titulo == titulo &&
        other.colunaStatus == colunaStatus &&
        other.prioridade == prioridade &&
        other.dataLimite == dataLimite;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tenantId.hashCode ^
        titulo.hashCode ^
        colunaStatus.hashCode ^
        prioridade.hashCode ^
        dataLimite.hashCode;
  }
}