import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String tenantId;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tenantId,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserModel(
      uid: id ?? map['uid'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      role: map['role'] ?? 'funcionario',
      createdAt: _parseTimestamp(map['created_at']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'tenant_id': tenantId,
      'role': role,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? tenantId,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tenantId: tenantId ?? this.tenantId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

