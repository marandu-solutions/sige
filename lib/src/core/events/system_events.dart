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
