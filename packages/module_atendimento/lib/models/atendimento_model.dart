import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um atendimento (antigo Card).
/// Contém tenantId para garantir isolamento de dados entre empresas.
class AtendimentoModel {
  final String id;
  final String tenantId;
  final String titulo;
  final String colunaStatus;
  final String prioridade;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime dataCriacao;
  final DateTime dataUltimaAtualizacao;
  final DateTime? dataEntradaColuna;
  final String status; // 'ativo', 'arquivado'
  final String ultimaMensagem;
  final DateTime? ultimaMensagemData;
  final int mensagensNaoLidas;

  final String? funcionarioResponsavelId;
  final String? leadId;
  final String? fotoUrl;

  AtendimentoModel({
    required this.id,
    required this.tenantId,
    required this.titulo,
    required this.colunaStatus,
    required this.prioridade,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.dataCriacao,
    required this.dataUltimaAtualizacao,
    this.dataEntradaColuna,
    this.status = 'ativo',
    this.ultimaMensagem = '',
    this.ultimaMensagemData,
    this.mensagensNaoLidas = 0,
    this.funcionarioResponsavelId,
    this.leadId,
    this.fotoUrl,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto AtendimentoModel.
  factory AtendimentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AtendimentoModel.fromMap(data, doc.id);
  }

  /// Converte um Map para AtendimentoModel
  factory AtendimentoModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AtendimentoModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      titulo: map['titulo'] ?? '',
      colunaStatus: map['coluna_status'] ?? 'novo',
      prioridade: map['prioridade'] ?? 'media',
      clienteNome: map['cliente_nome'] ?? '',
      clienteTelefone: map['cliente_telefone'] ?? '',
      dataCriacao:
          (map['data_criacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataUltimaAtualizacao:
          (map['data_ultima_atualizacao'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      dataEntradaColuna: (map['data_entrada_coluna'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'ativo',
      ultimaMensagem: map['ultima_mensagem'] ?? '',
      ultimaMensagemData: (map['ultima_mensagem_data'] as Timestamp?)?.toDate(),
      mensagensNaoLidas: map['mensagens_nao_lidas'] ?? 0,
      funcionarioResponsavelId: map['funcionario_responsavel_id'],
      leadId: map['lead_id'],
      fotoUrl: map['foto_url'],
    );
  }

  /// Converte o objeto AtendimentoModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'titulo': titulo,
      'coluna_status': colunaStatus,
      'prioridade': prioridade,
      'cliente_nome': clienteNome,
      'cliente_telefone': clienteTelefone,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'data_ultima_atualizacao': Timestamp.fromDate(dataUltimaAtualizacao),
      'data_entrada_coluna': dataEntradaColuna != null
          ? Timestamp.fromDate(dataEntradaColuna!)
          : null,
      'status': status,
      'ultima_mensagem': ultimaMensagem,
      'ultima_mensagem_data': ultimaMensagemData != null
          ? Timestamp.fromDate(ultimaMensagemData!)
          : null,
      'mensagens_nao_lidas': mensagensNaoLidas,
      'funcionario_responsavel_id': funcionarioResponsavelId,
      'lead_id': leadId,
      'foto_url': fotoUrl,
    };
  }

  /// Cria uma cópia do objeto com campos atualizados
  AtendimentoModel copyWith({
    String? id,
    String? tenantId,
    String? titulo,
    String? colunaStatus,
    String? prioridade,
    String? clienteNome,
    String? clienteTelefone,
    DateTime? dataCriacao,
    DateTime? dataUltimaAtualizacao,
    DateTime? dataEntradaColuna,
    String? status,
    String? ultimaMensagem,
    DateTime? ultimaMensagemData,
    int? mensagensNaoLidas,
    String? funcionarioResponsavelId,
    String? leadId,
    String? fotoUrl,
  }) {
    return AtendimentoModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      titulo: titulo ?? this.titulo,
      colunaStatus: colunaStatus ?? this.colunaStatus,
      prioridade: prioridade ?? this.prioridade,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataUltimaAtualizacao:
          dataUltimaAtualizacao ?? this.dataUltimaAtualizacao,
      dataEntradaColuna: dataEntradaColuna ?? this.dataEntradaColuna,
      status: status ?? this.status,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      ultimaMensagemData: ultimaMensagemData ?? this.ultimaMensagemData,
      mensagensNaoLidas: mensagensNaoLidas ?? this.mensagensNaoLidas,
      funcionarioResponsavelId:
          funcionarioResponsavelId ?? this.funcionarioResponsavelId,
      leadId: leadId ?? this.leadId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}
