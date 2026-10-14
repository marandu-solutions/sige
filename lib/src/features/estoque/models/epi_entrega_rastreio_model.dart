import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Rastreabilidade de Entrega de EPI e Régua de Atendimento.
/// Conecta a saída do estoque com o CRM Omnichannel para disparos preventivos
/// de reposição/recompra no WhatsApp antes do fim da vida útil.
class EpiEntregaRastreioModel {
  final String id;
  final String tenantId;
  final String itemId;
  final String nomeProduto;
  final String loteCodigo;
  final String? caNumero;
  final String? clienteId;
  final String clienteNome;
  final String clienteTelefone;
  final double quantidadeEntregue;
  final DateTime dataEntrega;
  final DateTime dataVencimentoUso;
  final int diasVidaUtil;
  final bool d30Disparado;
  final bool d15Disparado;
  final bool d0Disparado;
  final String statusRecompra; // PENDENTE, CONTATADO, RECOMPRA_CONFIRMADA, CANCELADO
  final String? atendimentoVinculadoId;
  final String? observacao;

  EpiEntregaRastreioModel({
    required this.id,
    required this.tenantId,
    required this.itemId,
    required this.nomeProduto,
    required this.loteCodigo,
    this.caNumero,
    this.clienteId,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.quantidadeEntregue,
    required this.dataEntrega,
    required this.dataVencimentoUso,
    required this.diasVidaUtil,
    this.d30Disparado = false,
    this.d15Disparado = false,
    this.d0Disparado = false,
    this.statusRecompra = 'PENDENTE',
    this.atendimentoVinculadoId,
    this.observacao,
  });

  int get diasRestantes => dataVencimentoUso.difference(DateTime.now()).inDays;
  bool get isUsoVencido => dataVencimentoUso.isBefore(DateTime.now());
  bool get isUsoPertoVencer => !isUsoVencido && diasRestantes <= 30;

  factory EpiEntregaRastreioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EpiEntregaRastreioModel.fromMap(data, doc.id);
  }

  factory EpiEntregaRastreioModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? fallback;
      }
      return fallback;
    }

    final regua = (map['regua_status'] as Map<String, dynamic>?) ?? {};

    return EpiEntregaRastreioModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      itemId: map['item_id'] ?? '',
      nomeProduto: map['nome_produto'] ?? '',
      loteCodigo: map['lote_codigo'] ?? '',
      caNumero: map['ca_numero'],
      clienteId: map['cliente_id'],
      clienteNome: map['cliente_nome'] ?? '',
      clienteTelefone: map['cliente_telefone'] ?? '',
      quantidadeEntregue: (map['quantidade_entregue'] ?? 1.0).toDouble(),
      dataEntrega: parseDate(map['data_entrega'], DateTime.now()),
      dataVencimentoUso: parseDate(
          map['data_vencimento_uso'],
          DateTime.now().add(const Duration(days: 60))),
      diasVidaUtil: (map['dias_vida_util'] ?? 60) as int,
      d30Disparado: map['d30_disparado'] ?? regua['d30_disparado'] ?? false,
      d15Disparado: map['d15_disparado'] ?? regua['d15_disparado'] ?? false,
      d0Disparado: map['d0_disparado'] ?? regua['d0_disparado'] ?? false,
      statusRecompra: map['status_recompra'] ?? 'PENDENTE',
      atendimentoVinculadoId: map['atendimento_vinculado_id'],
      observacao: map['observacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'item_id': itemId,
      'nome_produto': nomeProduto,
      'lote_codigo': loteCodigo,
      'ca_numero': caNumero,
      'cliente_id': clienteId,
      'cliente_nome': clienteNome,
      'cliente_telefone': clienteTelefone,
      'quantidade_entregue': quantidadeEntregue,
      'data_entrega': Timestamp.fromDate(dataEntrega),
      'data_vencimento_uso': Timestamp.fromDate(dataVencimentoUso),
      'dias_vida_util': diasVidaUtil,
      'd30_disparado': d30Disparado,
      'd15_disparado': d15Disparado,
      'd0_disparado': d0Disparado,
      'regua_status': {
        'd30_disparado': d30Disparado,
        'd15_disparado': d15Disparado,
        'd0_disparado': d0Disparado,
      },
      'status_recompra': statusRecompra,
      'atendimento_vinculado_id': atendimentoVinculadoId,
      'observacao': observacao,
    };
  }

  EpiEntregaRastreioModel copyWith({
    String? id,
    String? tenantId,
    String? itemId,
    String? nomeProduto,
    String? loteCodigo,
    String? caNumero,
    String? clienteId,
    String? clienteNome,
    String? clienteTelefone,
    double? quantidadeEntregue,
    DateTime? dataEntrega,
    DateTime? dataVencimentoUso,
    int? diasVidaUtil,
    bool? d30Disparado,
    bool? d15Disparado,
    bool? d0Disparado,
    String? statusRecompra,
    String? atendimentoVinculadoId,
    String? observacao,
  }) {
    return EpiEntregaRastreioModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      itemId: itemId ?? this.itemId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      caNumero: caNumero ?? this.caNumero,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      quantidadeEntregue: quantidadeEntregue ?? this.quantidadeEntregue,
      dataEntrega: dataEntrega ?? this.dataEntrega,
      dataVencimentoUso: dataVencimentoUso ?? this.dataVencimentoUso,
      diasVidaUtil: diasVidaUtil ?? this.diasVidaUtil,
      d30Disparado: d30Disparado ?? this.d30Disparado,
      d15Disparado: d15Disparado ?? this.d15Disparado,
      d0Disparado: d0Disparado ?? this.d0Disparado,
      statusRecompra: statusRecompra ?? this.statusRecompra,
      atendimentoVinculadoId:
          atendimentoVinculadoId ?? this.atendimentoVinculadoId,
      observacao: observacao ?? this.observacao,
    );
  }
}
