import 'package:cloud_firestore/cloud_firestore.dart';

class LeadModel {
  final String id;
  final String tenantId;
  final String nome;
  final String telefone;
  final String origem; // Ex: Facebook, Instagram, Site
  final String status; // Ex: Novo, Em Andamento, Convertido, Perdido
  final DateTime dataCriacao;
  final String? observacoes;
  final String? funcionario;
  final String? funcionarioId;

  LeadModel({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.telefone,
    required this.origem,
    required this.status,
    required this.dataCriacao,
    this.observacoes,
    this.funcionario,
    this.funcionarioId,
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
      origem: map['origem'] ?? 'Outros',
      status: map['status'] ?? 'Novo',
      dataCriacao:
          (map['data_criacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      observacoes: map['observacoes'],
      funcionario: map['funcionario'],
      funcionarioId: map['funcionarioId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'nome': nome,
      'telefone': telefone,
      'origem': origem,
      'status': status,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'observacoes': observacoes,
      'funcionario': funcionario,
      'funcionarioId': funcionarioId,
    };
  }

  LeadModel copyWith({
    String? id,
    String? tenantId,
    String? nome,
    String? telefone,
    String? origem,
    String? status,
    DateTime? dataCriacao,
    String? observacoes,
    String? funcionario,
    String? funcionarioId,
  }) {
    return LeadModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      origem: origem ?? this.origem,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      observacoes: observacoes ?? this.observacoes,
      funcionario: funcionario ?? this.funcionario,
      funcionarioId: funcionarioId ?? this.funcionarioId,
    );
  }
}
