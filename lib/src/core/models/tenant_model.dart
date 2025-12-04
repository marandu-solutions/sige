import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um tenant (empresa/cliente) no sistema.
/// Usado para buscar no Firebase quais módulos o cliente contratou.
class TenantModel {
  final String id;
  final String nomeFantasia;
  final String documentoFiscal;
  final String status;
  final List<String> modulosAtivos;
  final Map<String, dynamic> config;

  TenantModel({
    required this.id,
    required this.nomeFantasia,
    required this.documentoFiscal,
    required this.status,
    required this.modulosAtivos,
    required this.config,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto TenantModel.
  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantModel.fromMap(data, doc.id);
  }

  /// Converte um Map para TenantModel
  factory TenantModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return TenantModel(
      id: id ?? map['id'] ?? '',
      nomeFantasia: map['nome_fantasia'] ?? '',
      documentoFiscal: map['documento_fiscal'] ?? '',
      status: map['status'] ?? 'ativo',
      modulosAtivos: List<String>.from(map['modulos_ativos'] ?? []),
      config: Map<String, dynamic>.from(map['config'] ?? {}),
    );
  }

  /// Converte o objeto TenantModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome_fantasia': nomeFantasia,
      'documento_fiscal': documentoFiscal,
      'status': status,
      'modulos_ativos': modulosAtivos,
      'config': config,
    };
  }

  /// Verifica se um módulo específico está ativo para este tenant.
  bool hasModulo(String modulo) => modulosAtivos.contains(modulo);

  /// Retorna uma cópia do tenant com os dados atualizados.
  TenantModel copyWith({
    String? id,
    String? nomeFantasia,
    String? documentoFiscal,
    String? status,
    List<String>? modulosAtivos,
    Map<String, dynamic>? config,
  }) {
    return TenantModel(
      id: id ?? this.id,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      documentoFiscal: documentoFiscal ?? this.documentoFiscal,
      status: status ?? this.status,
      modulosAtivos: modulosAtivos ?? this.modulosAtivos,
      config: config ?? this.config,
    );
  }

  @override
  String toString() {
    return 'TenantModel(id: $id, nomeFantasia: $nomeFantasia, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TenantModel &&
        other.id == id &&
        other.nomeFantasia == nomeFantasia &&
        other.documentoFiscal == documentoFiscal &&
        other.status == status &&
        other.modulosAtivos == modulosAtivos &&
        other.config == config;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nomeFantasia.hashCode ^
        documentoFiscal.hashCode ^
        status.hashCode ^
        modulosAtivos.hashCode ^
        config.hashCode;
  }
}
