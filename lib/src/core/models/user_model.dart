import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um usuário no sistema.
/// Contém o tenantId para garantir isolamento de dados entre empresas.
class UserModel {
  final String id;
  final String nome;
  final String email;
  final String tenantId;
  final String role;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tenantId,
    required this.role,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto UserModel.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Converte um Map para UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserModel(
      id: id ?? map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      role: map['role'] ?? 'user',
    );
  }

  /// Converte o objeto UserModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'tenant_id': tenantId,
      'role': role,
    };
  }

  /// Retorna uma cópia do usuário com os dados atualizados.
  UserModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? tenantId,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tenantId: tenantId ?? this.tenantId,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nome: $nome, email: $email, tenantId: $tenantId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.nome == nome &&
        other.email == email &&
        other.tenantId == tenantId &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        email.hashCode ^
        tenantId.hashCode ^
        role.hashCode;
  }
}