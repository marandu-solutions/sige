import 'package:cloud_firestore/cloud_firestore.dart';

class LeadModel {
  final String id;
  final String tenantId;
  final String nome;
  final String email;
  final String telefone;
  final String origem; // Ex: Facebook, Instagram, Site
  final String status; // Ex: Novo, Em Andamento, Convertido, Perdido
  final DateTime dataCriacao;
  final String? observacoes;

  LeadModel({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.origem,
    required this.status,
    required this.dataCriacao,
    this.observacoes,
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
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      origem: map['origem'] ?? 'Outros',
      status: map['status'] ?? 'Novo',
      dataCriacao: (map['data_criacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'origem': origem,
      'status': status,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'observacoes': observacoes,
    };
  }

  LeadModel copyWith({
    String? id,
    String? tenantId,
    String? nome,
    String? email,
    String? telefone,
    String? origem,
    String? status,
    DateTime? dataCriacao,
    String? observacoes,
  }) {
    return LeadModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      origem: origem ?? this.origem,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}
