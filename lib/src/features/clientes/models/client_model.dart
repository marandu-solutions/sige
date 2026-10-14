import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_address_model.dart';

/// Modelo de Cliente Polimórfico do SIGE (MD05)
/// Suporta Pessoa Jurídica (PJ), Contato Vinculado (CONTATO_PJ) e Pessoa Física (PF).
class ClientModel {
  final String id;
  final String tenantId;
  final String tipo; // 'PJ' | 'PF' | 'CONTATO_PJ'
  final String nome; // Nome Fantasia ou Nome da Pessoa
  final String? razaoSocial; // Para PJ
  final String? documento; // CNPJ ou CPF (apenas números)
  final String? inscricaoEstadual;

  // Comunicação & Multi-Telefones
  final List<String> telefones;
  final String telefonePrincipal;
  final List<String> emails;

  // Relacionamento B2B
  final String? empresaId; // Se for CONTATO_PJ, aponta para o ID da PJ
  final String? empresaNome; // Desnormalizado para agilidade no Kanban/Cards
  final String? cargo; // Ex: 'Comprador', 'Mestre de Obras', 'Engenheiro TST'
  final List<String> contatosVinculadosIds; // Se for PJ, guarda IDs dos colaboradores

  // Ciclo de Vida & Segmentação
  final String statusCiclo; // 'LEAD', 'ATIVO', 'INATIVO', 'BLOQUEADO'
  final List<String> tags; // Ex: ['VIP', 'CONSTRUTORA', 'RECORRENTE']
  final String origem; // 'WHATSAPP', 'INDICACAO', 'BALCAO', 'SITE'

  // Dados Comerciais & Financeiros
  final double? limiteCredito;
  final String? tabelaPreco; // 'PADRAO', 'TABELA_A', 'ATACADO'
  final double ltvTotal; // Total faturado acumulado
  final int totalAtendimentos;
  final DateTime? ultimaCompraData;

  // Endereço Estruturado
  final ClientAddressModel? endereco;

  // Auditoria
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? responsavelUserId;
  final String? observacoesInternas;
  final String? fotoUrl;

  final Map<String, dynamic> metadata;

  const ClientModel({
    required this.id,
    required this.tenantId,
    required this.tipo,
    required this.nome,
    this.razaoSocial,
    this.documento,
    this.inscricaoEstadual,
    required this.telefones,
    required this.telefonePrincipal,
    this.emails = const [],
    this.empresaId,
    this.empresaNome,
    this.cargo,
    this.contatosVinculadosIds = const [],
    this.statusCiclo = 'LEAD',
    this.tags = const [],
    this.origem = 'WHATSAPP',
    this.limiteCredito,
    this.tabelaPreco,
    this.ltvTotal = 0.0,
    this.totalAtendimentos = 0,
    this.ultimaCompraData,
    this.endereco,
    required this.criadoEm,
    required this.atualizadoEm,
    this.responsavelUserId,
    this.observacoesInternas,
    this.fotoUrl,
    this.metadata = const {},
  });

  bool get isPj => tipo == 'PJ';
  bool get isContatoPj => tipo == 'CONTATO_PJ';
  bool get isPf => tipo == 'PF';

  /// Retorna o nome de exibição contextual
  String get nomeExibicao {
    if (isContatoPj && empresaNome != null && empresaNome!.isNotEmpty) {
      final cargoStr = (cargo != null && cargo!.isNotEmpty) ? ' ($cargo)' : '';
      return '$nome$cargoStr • $empresaNome';
    }
    return nome;
  }

  /// Formatação do CNPJ ou CPF para a UI
  String get documentoFormatado {
    if (documento == null || documento!.isEmpty) return 'Não informado';
    final clean = documento!.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 14) {
      // CNPJ: 00.000.000/0000-00
      return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12, 14)}';
    } else if (clean.length == 11) {
      // CPF: 000.000.000-00
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
    }
    return documento!;
  }

  /// Formatação visual do telefone principal
  String get telefoneFormatado {
    final clean = telefonePrincipal.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      // (11) 98888-7777
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7, 11)}';
    } else if (clean.length == 10) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6, 10)}';
    } else if (clean.length == 13 && clean.startsWith('55')) {
      // 55 11 98888-7777
      return '+55 (${clean.substring(2, 4)}) ${clean.substring(4, 9)}-${clean.substring(9, 13)}';
    }
    return telefonePrincipal;
  }

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClientModel.fromMap(data, doc.id);
  }

  factory ClientModel.fromMap(Map<String, dynamic> map, [String? id]) {
    String? parseStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is Timestamp) return d.toDate();
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
      return DateTime.now();
    }

    // Tratamento de telefones: compatibilidade com campo legado 'telefone' e 'telefones'
    List<String> tels = [];
    if (map['telefones'] is List) {
      tels = (map['telefones'] as List)
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final telLegado = parseStr(map['telefone']);
    if (telLegado != null && !tels.contains(telLegado)) {
      tels.insert(0, telLegado);
    }
    final telPrincipalRaw = parseStr(map['telefone_principal']);
    final principal = (telPrincipalRaw != null && telPrincipalRaw.isNotEmpty)
        ? telPrincipalRaw
        : (tels.isNotEmpty ? tels.first : (telLegado ?? ''));

    // Documento
    final docLimpo = (parseStr(map['documento']) ??
            parseStr(map['cnpj']) ??
            parseStr(map['cpf']))
        ?.replaceAll(RegExp(r'\D'), '');

    // Tipo de cliente com fallback inteligente
    String tipoClient = parseStr(map['tipo'])?.toUpperCase() ?? 'PF';
    if (map['tipo'] == null) {
      if (docLimpo != null && docLimpo.length == 14) {
        tipoClient = 'PJ';
      } else if (map['empresa_id'] != null) {
        tipoClient = 'CONTATO_PJ';
      }
    }

    // Endereço
    ClientAddressModel? end;
    if (map['endereco'] is Map) {
      end = ClientAddressModel.fromMap(
          Map<String, dynamic>.from(map['endereco'] as Map));
    }

    return ClientModel(
      id: id ?? parseStr(map['id']) ?? '',
      tenantId: parseStr(map['tenant_id']) ?? '',
      tipo: tipoClient,
      nome: parseStr(map['nome']) ??
          parseStr(map['nome_fantasia']) ??
          parseStr(map['razao_social']) ??
          'Cliente Sem Nome',
      razaoSocial: parseStr(map['razao_social']),
      documento: docLimpo,
      inscricaoEstadual: parseStr(map['inscricao_estadual']),
      telefones: tels,
      telefonePrincipal: principal,
      emails: (map['emails'] is List)
          ? (map['emails'] as List)
              .where((e) => e != null)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : (map['email'] != null ? [map['email'].toString().trim()] : []),
      empresaId: parseStr(map['empresa_id']),
      empresaNome: parseStr(map['empresa_nome']),
      cargo: parseStr(map['cargo']),
      contatosVinculadosIds: (map['contatos_vinculados_ids'] is List)
          ? (map['contatos_vinculados_ids'] as List)
              .where((e) => e != null)
              .map((e) => e.toString().trim())
              .toList()
          : [],
      statusCiclo: parseStr(map['status_ciclo']) ??
          parseStr(map['status']) ??
          'LEAD',
      tags: (map['tags'] is List)
          ? (map['tags'] as List)
              .where((e) => e != null)
              .map((e) => e.toString().trim())
              .toList()
          : [],
      origem: parseStr(map['origem']) ?? 'WHATSAPP',
      limiteCredito: (map['limite_credito'] as num?)?.toDouble(),
      tabelaPreco: parseStr(map['tabela_preco']) ?? 'PADRAO',
      ltvTotal: (map['ltv_total'] as num?)?.toDouble() ?? 0.0,
      totalAtendimentos: (map['total_atendimentos'] as num?)?.toInt() ?? 0,
      ultimaCompraData: map['ultima_compra_data'] != null
          ? parseDate(map['ultima_compra_data'])
          : null,
      endereco: end,
      criadoEm: parseDate(map['criado_em'] ?? map['data_criacao']),
      atualizadoEm: parseDate(map['atualizado_em']),
      responsavelUserId: parseStr(map['responsavel_user_id']) ??
          parseStr(map['funcionarioId']),
      observacoesInternas: parseStr(map['observacoes_internas']) ??
          parseStr(map['observacoes']),
      fotoUrl: parseStr(map['foto_url']) ?? parseStr(map['fotoUrl']),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'tipo': tipo,
      'nome': nome,
      'razao_social': razaoSocial,
      'documento': documento,
      'inscricao_estadual': inscricaoEstadual,
      'telefones': telefones,
      'telefone_principal': telefonePrincipal,
      'emails': emails,
      'empresa_id': empresaId,
      'empresa_nome': empresaNome,
      'cargo': cargo,
      'contatos_vinculados_ids': contatosVinculadosIds,
      'status_ciclo': statusCiclo,
      'tags': tags,
      'origem': origem,
      'limite_credito': limiteCredito,
      'tabela_preco': tabelaPreco,
      'ltv_total': ltvTotal,
      'total_atendimentos': totalAtendimentos,
      'ultima_compra_data': ultimaCompraData != null ? Timestamp.fromDate(ultimaCompraData!) : null,
      'endereco': endereco?.toMap(),
      'criado_em': Timestamp.fromDate(criadoEm),
      'atualizado_em': Timestamp.fromDate(atualizadoEm),
      'responsavel_user_id': responsavelUserId,
      'observacoes_internas': observacoesInternas,
      'foto_url': fotoUrl,
      'metadata': metadata,
      // Compatibilidade legada com a coleção leads
      'telefone': telefonePrincipal,
      'status': statusCiclo,
      'data_criacao': Timestamp.fromDate(criadoEm),
    };
  }

  ClientModel copyWith({
    String? id,
    String? tenantId,
    String? tipo,
    String? nome,
    String? razaoSocial,
    String? documento,
    String? inscricaoEstadual,
    List<String>? telefones,
    String? telefonePrincipal,
    List<String>? emails,
    String? empresaId,
    String? empresaNome,
    String? cargo,
    List<String>? contatosVinculadosIds,
    String? statusCiclo,
    List<String>? tags,
    String? origem,
    double? limiteCredito,
    String? tabelaPreco,
    double? ltvTotal,
    int? totalAtendimentos,
    DateTime? ultimaCompraData,
    ClientAddressModel? endereco,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? responsavelUserId,
    String? observacoesInternas,
    String? fotoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ClientModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      documento: documento ?? this.documento,
      inscricaoEstadual: inscricaoEstadual ?? this.inscricaoEstadual,
      telefones: telefones ?? this.telefones,
      telefonePrincipal: telefonePrincipal ?? this.telefonePrincipal,
      emails: emails ?? this.emails,
      empresaId: empresaId ?? this.empresaId,
      empresaNome: empresaNome ?? this.empresaNome,
      cargo: cargo ?? this.cargo,
      contatosVinculadosIds: contatosVinculadosIds ?? this.contatosVinculadosIds,
      statusCiclo: statusCiclo ?? this.statusCiclo,
      tags: tags ?? this.tags,
      origem: origem ?? this.origem,
      limiteCredito: limiteCredito ?? this.limiteCredito,
      tabelaPreco: tabelaPreco ?? this.tabelaPreco,
      ltvTotal: ltvTotal ?? this.ltvTotal,
      totalAtendimentos: totalAtendimentos ?? this.totalAtendimentos,
      ultimaCompraData: ultimaCompraData ?? this.ultimaCompraData,
      endereco: endereco ?? this.endereco,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      responsavelUserId: responsavelUserId ?? this.responsavelUserId,
      observacoesInternas: observacoesInternas ?? this.observacoesInternas,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
