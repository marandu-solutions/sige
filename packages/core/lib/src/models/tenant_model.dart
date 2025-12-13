import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantModel.fromMap(data, doc.id);
  }

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

  Map<String, dynamic> toMap() {
    return {
      'nome_fantasia': nomeFantasia,
      'documento_fiscal': documentoFiscal,
      'status': status,
      'modulos_ativos': modulosAtivos,
      'config': config,
    };
  }

  bool hasModulo(String modulo) => modulosAtivos.contains(modulo);

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
}

