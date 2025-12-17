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

  // Campos adicionais para integração N8N
  final String status; // 'pending_send', 'sent', 'error', etc.
  final String? remetenteUid;
  final String? remetenteTipo; // 'vendedor', 'sistema', 'cliente'
  final String? telefoneDestino;
  final String? leadId;
  final String? mensagemTipo;

  MensagemModel({
    required this.id,
    required this.tenantId,
    required this.atendimentoId,
    required this.texto,
    required this.isUsuario,
    required this.dataEnvio,
    this.anexoUrl,
    this.anexoTipo,
    this.status =
        'sent', // Default para retrocompatibilidade ou mensagens recebidas
    this.remetenteUid,
    this.remetenteTipo,
    this.telefoneDestino,
    this.leadId,
    this.mensagemTipo,
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
      dataEnvio: _parseTimestamp(map['data_envio']) ??
          _parseTimestamp(map['sent_at']) ??
          DateTime.now(),
      anexoUrl: map['anexo_url'],
      anexoTipo: map['anexo_tipo'],
      status: map['status'] ?? 'sent',
      remetenteUid: map['remetente_uid'],
      remetenteTipo: map['remetente_tipo'],
      telefoneDestino: map['telefone_destino'],
      leadId: map['lead_id'],
      mensagemTipo: map['mensagemTipo'],
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  /// Converte o objeto MensagemModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'tenant_id': tenantId,
      'atendimento_id': atendimentoId,
      'texto': texto,
      'is_usuario': isUsuario,
      // Usa sent_at para compatibilidade com a Cloud Function/N8N, mas mantém data_envio para legado se necessário
      'data_envio': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(dataEnvio),
      'sent_at': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(dataEnvio),
      'anexo_url': anexoUrl,
      'anexo_tipo': anexoTipo,
      'status': status,
      'remetente_uid': remetenteUid,
      'remetente_tipo': remetenteTipo,
      'telefone_destino': telefoneDestino,
      'lead_id': leadId,
      'mensagemTipo': mensagemTipo,
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
    String? status,
    String? remetenteUid,
    String? remetenteTipo,
    String? telefoneDestino,
    String? leadId,
    String? mensagemTipo,
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
      status: status ?? this.status,
      remetenteUid: remetenteUid ?? this.remetenteUid,
      remetenteTipo: remetenteTipo ?? this.remetenteTipo,
      telefoneDestino: telefoneDestino ?? this.telefoneDestino,
      leadId: leadId ?? this.leadId,
      mensagemTipo: mensagemTipo ?? this.mensagemTipo,
    );
  }
}
