import 'event_bus.dart';

class NewLeadEvent extends SigeEvent {
  final String tenantId;
  final String leadId;
  final String leadName;
  final String? telefone;
  final double? latitude;
  final double? longitude;

  NewLeadEvent({
    required this.tenantId,
    required this.leadId,
    required this.leadName,
    this.telefone,
    this.latitude,
    this.longitude,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'tenantId': tenantId,
      'leadId': leadId,
      'leadName': leadName,
      'telefone': telefone,
      'latitude': latitude,
      'longitude': longitude,
    });
    return map;
  }
}

class SaleConfirmedEvent extends SigeEvent {
  final String tenantId;
  final String atendimentoId;
  final String? productId;
  final int quantity;
  final double totalValue;

  SaleConfirmedEvent({
    required this.tenantId,
    required this.atendimentoId,
    this.productId,
    required this.quantity,
    required this.totalValue,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'tenantId': tenantId,
      'atendimentoId': atendimentoId,
      'productId': productId,
      'quantity': quantity,
      'totalValue': totalValue,
    });
    return map;
  }
}

enum AlertType { info, success, warning, error }

/// Event fired to show a global alert/notification to the user
class AlertEvent extends SigeEvent {
  final String message;
  final AlertType type;

  AlertEvent({
    required this.message,
    this.type = AlertType.info,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'message': message,
      'type': type.toString(),
    });
    return map;
  }
}

/// Disparado quando um EPI entregue atinge a janela de vencimento em uso (D-30, D-15 ou D-0)
class EpiExpiringEvent extends SigeEvent {
  final String tenantId;
  final String rastreioId;
  final String clienteNome;
  final String clienteTelefone;
  final String nomeProduto;
  final String? caNumero;
  final int diasRestantes;

  EpiExpiringEvent({
    required this.tenantId,
    required this.rastreioId,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.nomeProduto,
    this.caNumero,
    required this.diasRestantes,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'tenantId': tenantId,
      'rastreioId': rastreioId,
      'clienteNome': clienteNome,
      'clienteTelefone': clienteTelefone,
      'nomeProduto': nomeProduto,
      'caNumero': caNumero,
      'diasRestantes': diasRestantes,
    });
    return map;
  }
}

/// Disparado quando um item de estoque atinge ou fica abaixo do estoque mínimo
class StockBelowThresholdEvent extends SigeEvent {
  final String tenantId;
  final String itemId;
  final String nomeProduto;
  final double qtdAtual;
  final double nivelAlerta;

  StockBelowThresholdEvent({
    required this.tenantId,
    required this.itemId,
    required this.nomeProduto,
    required this.qtdAtual,
    required this.nivelAlerta,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'tenantId': tenantId,
      'itemId': itemId,
      'nomeProduto': nomeProduto,
      'qtdAtual': qtdAtual,
      'nivelAlerta': nivelAlerta,
    });
    return map;
  }
}

/// Disparado quando ocorre entrega de EPI com controle de vida útil
class EpiDeliveredEvent extends SigeEvent {
  final String tenantId;
  final String itemId;
  final String nomeProduto;
  final String loteCodigo;
  final String clienteNome;
  final String clienteTelefone;
  final double quantidade;
  final int diasVidaUtil;

  EpiDeliveredEvent({
    required this.tenantId,
    required this.itemId,
    required this.nomeProduto,
    required this.loteCodigo,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.quantidade,
    required this.diasVidaUtil,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'tenantId': tenantId,
      'itemId': itemId,
      'nomeProduto': nomeProduto,
      'loteCodigo': loteCodigo,
      'clienteNome': clienteNome,
      'clienteTelefone': clienteTelefone,
      'quantidade': quantidade,
      'diasVidaUtil': diasVidaUtil,
    });
    return map;
  }
}

