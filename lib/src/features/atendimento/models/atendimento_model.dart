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
  final String? funcionarioResponsavelNome;
  final String? leadId;
  final String? fotoUrl;

  final String? protocolo;
  final bool isAtivo;
  final Map<String, dynamic> metadata;

  // Campos de Inteligência Financeira e Segmentação (MD06)
  final double? valorEstimado;
  final String? categoriaTicket; // 'alto_ticket', 'medio_ticket', 'baixo_ticket'
  final String? tipoCliente; // 'B2B_CORPORATIVO', 'B2B_PEQUENO', 'B2C_VAREJO'
  final int? quantidadeItensEstimada;
  final DateTime? ultimoFollowUpEm;

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
    this.funcionarioResponsavelNome,
    this.leadId,
    this.fotoUrl,
    this.protocolo,
    this.isAtivo = true,
    this.metadata = const {},
    this.valorEstimado,
    this.categoriaTicket,
    this.tipoCliente,
    this.quantidadeItensEstimada,
    this.ultimoFollowUpEm,
  });

  /// Converte um DocumentSnapshot do Firestore para um objeto AtendimentoModel.
  factory AtendimentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AtendimentoModel.fromMap(data, doc.id);
  }

  /// Converte um Map para AtendimentoModel
  factory AtendimentoModel.fromMap(Map<String, dynamic> map, [String? id]) {
    // Tenta obter valor estimado tanto de campo direto quanto de metadata
    double? valor;
    if (map['valor_estimado'] != null) {
      valor = double.tryParse(map['valor_estimado'].toString());
    } else if (map['metadata']?['valor_estimado'] != null) {
      valor = double.tryParse(map['metadata']['valor_estimado'].toString());
    }

    return AtendimentoModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      titulo: map['titulo'] ?? '',
      colunaStatus: map['coluna_status'] ?? map['colunaStatus'] ?? 'novo',
      prioridade: map['prioridade'] ?? 'media',
      clienteNome: map['cliente_nome'] ?? map['clienteNome'] ?? '',
      clienteTelefone: map['cliente_telefone'] ?? map['clienteTelefone'] ?? '',
      dataCriacao:
          (map['data_criacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataUltimaAtualizacao:
          (map['data_ultima_atualizacao'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      dataEntradaColuna: (map['data_entrada_coluna'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'ativo',
      ultimaMensagem: map['ultima_mensagem'] ?? '',
      ultimaMensagemData: (map['ultima_mensagem_data'] as Timestamp?)?.toDate(),
      mensagensNaoLidas:
          int.tryParse(map['mensagens_nao_lidas']?.toString() ?? '0') ?? 0,
      funcionarioResponsavelId: map['funcionario_responsavel_id'],
      funcionarioResponsavelNome: map['funcionario_responsavel_nome'] ??
          map['funcionarioResponsavelNome'],
      leadId: map['lead_id'],
      fotoUrl: map['foto_url'] ?? map['fotoUrl'],
      protocolo: map['protocolo'],
      isAtivo: map['is_ativo'] ?? true,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
      valorEstimado: valor,
      categoriaTicket: map['categoria_ticket'] ?? map['metadata']?['categoria_ticket'],
      tipoCliente: map['tipo_cliente'] ?? map['metadata']?['tipo_cliente'],
      quantidadeItensEstimada: int.tryParse(map['quantidade_itens_estimada']?.toString() ?? map['metadata']?['quantidade_itens_estimada']?.toString() ?? ''),
      ultimoFollowUpEm: (map['ultimo_follow_up_em'] as Timestamp?)?.toDate(),
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
      'funcionario_responsavel_nome': funcionarioResponsavelNome,
      'lead_id': leadId,
      'foto_url': fotoUrl,
      'protocolo': protocolo,
      'is_ativo': isAtivo,
      'metadata': metadata,
      'valor_estimado': valorEstimado,
      'categoria_ticket': categoriaTicket,
      'tipo_cliente': tipoCliente,
      'quantidade_itens_estimada': quantidadeItensEstimada,
      'ultimo_follow_up_em': ultimoFollowUpEm != null
          ? Timestamp.fromDate(ultimoFollowUpEm!)
          : null,
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
    String? funcionarioResponsavelNome,
    String? leadId,
    String? fotoUrl,
    String? protocolo,
    bool? isAtivo,
    Map<String, dynamic>? metadata,
    double? valorEstimado,
    String? categoriaTicket,
    String? tipoCliente,
    int? quantidadeItensEstimada,
    DateTime? ultimoFollowUpEm,
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
      funcionarioResponsavelNome:
          funcionarioResponsavelNome ?? this.funcionarioResponsavelNome,
      leadId: leadId ?? this.leadId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      protocolo: protocolo ?? this.protocolo,
      isAtivo: isAtivo ?? this.isAtivo,
      metadata: metadata ?? this.metadata,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      categoriaTicket: categoriaTicket ?? this.categoriaTicket,
      tipoCliente: tipoCliente ?? this.tipoCliente,
      quantidadeItensEstimada:
          quantidadeItensEstimada ?? this.quantidadeItensEstimada,
      ultimoFollowUpEm: ultimoFollowUpEm ?? this.ultimoFollowUpEm,
    );
  }

  // --- Getters Utilitários de Negócio (EPI & B2B) ---

  /// Retorna o valor estimado em R$ (ou busca em metadata caso preenchido)
  double get valorEstimadoCalculado {
    if (valorEstimado != null && valorEstimado! > 0) return valorEstimado!;
    if (metadata['valor_estimado'] != null) {
      return double.tryParse(metadata['valor_estimado'].toString()) ?? 0.0;
    }
    if (metadata['valor'] != null) {
      return double.tryParse(metadata['valor'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  /// Indica se é uma conta B2B de alto ticket / VIP (>= R$ 5.000 ou explicitamente B2B Corporativo)
  bool get isB2BVip {
    if (valorEstimadoCalculado >= 5000.0) return true;
    if (categoriaTicket == 'alto_ticket') return true;
    if (tipoCliente == 'B2B_CORPORATIVO') return true;
    if (metadata['is_vip'] == true || metadata['vip'] == true) return true;
    return false;
  }

  /// Indica se é cliente de baixo ticket / varejo / balcão (< R$ 500)
  bool get isBaixoTicket {
    if (valorEstimadoCalculado > 0 && valorEstimadoCalculado < 500.0) return true;
    if (categoriaTicket == 'baixo_ticket') return true;
    if (tipoCliente == 'B2C_VAREJO') return true;
    return false;
  }

  /// Rótulo visual do ticket para badges
  String get ticketBadgeLabel {
    if (isB2BVip) return 'B2B VIP';
    if (isBaixoTicket) return 'Balcão/Varejo';
    if (tipoCliente == 'B2B_PEQUENO') return 'B2B';
    return 'Geral';
  }
}
