import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa uma mensagem no chat de atendimento
class MensagemModel {
  final String id;
  final String tenantId;
  final String atendimentoId;
  final String texto;
  final bool
      isUsuario; // true se for do usuário do sistema, false se for do cliente
  final DateTime dataEnvio;
  final String? anexoUrl;
  final String? anexoTipo;

  MensagemModel({
    required this.id,
    required this.tenantId,
    required this.atendimentoId,
    required this.texto,
    required this.isUsuario,
    required this.dataEnvio,
    this.anexoUrl,
    this.anexoTipo,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto MensagemModel.
  factory MensagemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MensagemModel.fromMap(data, doc.id);
  }

  /// Converte um Map para MensagemModel
  factory MensagemModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return MensagemModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      atendimentoId: map['atendimento_id'] ?? '',
      texto: map['texto'] ?? '',
      isUsuario: map['is_usuario'] ?? false,
      dataEnvio: (map['data_envio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      anexoUrl: map['anexo_url'],
      anexoTipo: map['anexo_tipo'],
    );
  }

  /// Converte o objeto MensagemModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'atendimento_id': atendimentoId,
      'texto': texto,
      'is_usuario': isUsuario,
      'data_envio': Timestamp.fromDate(dataEnvio),
      'anexo_url': anexoUrl,
      'anexo_tipo': anexoTipo,
    };
  }

  /// Cria uma cópia do objeto com campos atualizados
  MensagemModel copyWith({
    String? id,
    String? tenantId,
    String? atendimentoId,
    String? texto,
    bool? isUsuario,
    DateTime? dataEnvio,
    String? anexoUrl,
    String? anexoTipo,
  }) {
    return MensagemModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      atendimentoId: atendimentoId ?? this.atendimentoId,
      texto: texto ?? this.texto,
      isUsuario: isUsuario ?? this.isUsuario,
      dataEnvio: dataEnvio ?? this.dataEnvio,
      anexoUrl: anexoUrl ?? this.anexoUrl,
      anexoTipo: anexoTipo ?? this.anexoTipo,
    );
  }
}
