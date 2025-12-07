import 'package:cloud_firestore/cloud_firestore.dart';

class FuncionarioModel {
  final String id;
  final String tenantId;
  final String nome;
  final String? email;
  final String? cargo;
  final String? telefone;
  final String? fotoUrl;
  final bool ativo;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

  FuncionarioModel({
    required this.id,
    required this.tenantId,
    required this.nome,
    this.email,
    this.cargo,
    this.telefone,
    this.fotoUrl,
    this.ativo = true,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  factory FuncionarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FuncionarioModel.fromMap(data, doc.id);
  }

  factory FuncionarioModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return FuncionarioModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'],
      cargo: map['cargo'],
      telefone: map['telefone'],
      fotoUrl: map['foto_url'],
      ativo: map['ativo'] ?? true,
      dataCriacao: _parseTimestamp(map['data_criacao']) ?? DateTime.now(),
      dataAtualizacao: _parseTimestamp(map['data_atualizacao']) ?? DateTime.now(),
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
      'email': email,
      'cargo': cargo,
      'telefone': telefone,
      'foto_url': fotoUrl,
      'ativo': ativo,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'data_atualizacao': Timestamp.fromDate(dataAtualizacao),
    };
  }

  FuncionarioModel copyWith({
    String? id,
    String? tenantId,
    String? nome,
    String? email,
    String? cargo,
    String? telefone,
    String? fotoUrl,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return FuncionarioModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cargo: cargo ?? this.cargo,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
