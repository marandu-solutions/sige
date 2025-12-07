import 'package:cloud_firestore/cloud_firestore.dart';

class LeadModel {
  final String id;
  final String tenantId;
  final String nome;
  final String telefone;
  final String? email;
  final String status; // Pode ser o ID da coluna do Kanban ou um status geral
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final Map<String, dynamic> metadata;

  final String? funcionarioResponsavelId;
  final String? funcionarioResponsavelNome;

  LeadModel({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.telefone,
    this.email,
    required this.status,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.metadata = const {},
    this.funcionarioResponsavelId,
    this.funcionarioResponsavelNome,
  });

  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeadModel.fromMap(data, doc.id);
  }

  factory LeadModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LeadModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'],
      status: map['status'] ?? 'novo',
      dataCriacao: _parseTimestamp(map['data_criacao']) ?? DateTime.now(),
      dataAtualizacao:
          _parseTimestamp(map['data_atualizacao']) ?? DateTime.now(),
      metadata: map['metadata'] ?? {},
      funcionarioResponsavelId: map['funcionario_responsavel_id'],
      funcionarioResponsavelNome: map['funcionario_responsavel_nome'],
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'status': status,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'data_atualizacao': Timestamp.fromDate(dataAtualizacao),
      'metadata': metadata,
      'funcionario_responsavel_id': funcionarioResponsavelId,
      'funcionario_responsavel_nome': funcionarioResponsavelNome,
    };
  }

  LeadModel copyWith({
    String? id,
    String? tenantId,
    String? nome,
    String? telefone,
    String? email,
    String? status,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    Map<String, dynamic>? metadata,
    String? funcionarioResponsavelId,
    String? funcionarioResponsavelNome,
  }) {
    return LeadModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      metadata: metadata ?? this.metadata,
      funcionarioResponsavelId:
          funcionarioResponsavelId ?? this.funcionarioResponsavelId,
      funcionarioResponsavelNome:
          funcionarioResponsavelNome ?? this.funcionarioResponsavelNome,
    );
  }
}
