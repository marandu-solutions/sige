import 'event_bus.dart';

/// Event fired when a new lead is created or assigned
class NewLeadEvent extends SigeEvent {
  final String tenantId;
  final String leadId;
  final String leadName;
  final double? latitude;
  final double? longitude;

  NewLeadEvent({
    required this.tenantId,
    required this.leadId,
    required this.leadName,
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
      'latitude': latitude,
      'longitude': longitude,
    });
    return map;
  }
}

/// Event fired when a sale is confirmed (e.g. Atendimento closed with success)
class SaleConfirmedEvent extends SigeEvent {
  final String tenantId;
  final String atendimentoId;
  final String productId;
  final int quantity;
  final double totalValue;

  SaleConfirmedEvent({
    required this.tenantId,
    required this.atendimentoId,
    required this.productId,
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

enum AlertType { info, success, warning, error }
