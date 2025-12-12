import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um atendimento no Kanban.
/// Contém tenantId para garantir isolamento de dados entre empresas.
class AtendimentoCardModel {
  final String id;
  final String tenantId;
  final String titulo;
  final String colunaStatus;
  final String prioridade;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime dataCriacao;
  final String ultimaMensagem;
  final DateTime? ultimaMensagemData;
  final int mensagensNaoLidas;

  final String? funcionarioResponsavelId;
  final String? leadId;

  AtendimentoCardModel({
    required this.id,
    required this.tenantId,
    required this.titulo,
    required this.colunaStatus,
    required this.prioridade,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.dataCriacao,
    this.ultimaMensagem = '',
    this.ultimaMensagemData,
    this.mensagensNaoLidas = 0,
    this.funcionarioResponsavelId,
    this.leadId,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto AtendimentoCardModel.
  factory AtendimentoCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AtendimentoCardModel.fromMap(data, doc.id);
  }

  /// Converte um Map para AtendimentoCardModel
  factory AtendimentoCardModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AtendimentoCardModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      titulo: map['titulo'] ?? '',
      colunaStatus: map['coluna_status'] ?? 'novo',
      prioridade: map['prioridade'] ?? 'media',
      clienteNome: map['cliente_nome'] ?? '',
      clienteTelefone: map['cliente_telefone'] ?? '',
      dataCriacao:
          (map['data_criacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ultimaMensagem: map['ultima_mensagem'] ?? '',
      ultimaMensagemData: (map['ultima_mensagem_data'] as Timestamp?)?.toDate(),
      mensagensNaoLidas: map['mensagens_nao_lidas'] ?? 0,
      funcionarioResponsavelId: map['funcionario_responsavel_id'],
      leadId: map['lead_id'],
    );
  }

  /// Converte o objeto AtendimentoCardModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'titulo': titulo,
      'coluna_status': colunaStatus,
      'prioridade': prioridade,
      'cliente_nome': clienteNome,
      'cliente_telefone': clienteTelefone,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'ultima_mensagem': ultimaMensagem,
      'ultima_mensagem_data': ultimaMensagemData != null
          ? Timestamp.fromDate(ultimaMensagemData!)
          : null,
      'mensagens_nao_lidas': mensagensNaoLidas,
      'funcionario_responsavel_id': funcionarioResponsavelId,
      'lead_id': leadId,
    };
  }

  /// Cria uma cópia do objeto com campos atualizados
  AtendimentoCardModel copyWith({
    String? id,
    String? tenantId,
    String? titulo,
    String? colunaStatus,
    String? prioridade,
    String? clienteNome,
    String? clienteTelefone,
    DateTime? dataCriacao,
    String? ultimaMensagem,
    DateTime? ultimaMensagemData,
    int? mensagensNaoLidas,
    String? funcionarioResponsavelId,
    String? leadId,
  }) {
    return AtendimentoCardModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      titulo: titulo ?? this.titulo,
      colunaStatus: colunaStatus ?? this.colunaStatus,
      prioridade: prioridade ?? this.prioridade,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      ultimaMensagemData: ultimaMensagemData ?? this.ultimaMensagemData,
      mensagensNaoLidas: mensagensNaoLidas ?? this.mensagensNaoLidas,
      funcionarioResponsavelId:
          funcionarioResponsavelId ?? this.funcionarioResponsavelId,
      leadId: leadId ?? this.leadId,
    );
  }
}
