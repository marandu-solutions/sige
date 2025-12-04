import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KanbanColumnModel {
  final String id;
  final String tenantId;
  final String title;
  final int colorValue;
  final int order;

  KanbanColumnModel({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.colorValue,
    required this.order,
  });

  Color get color => Color(colorValue);

  KanbanColumnModel copyWith({
    String? id,
    String? tenantId,
    String? title,
    int? colorValue,
    int? order,
  }) {
    return KanbanColumnModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
      order: order ?? this.order,
    );
  }

  factory KanbanColumnModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KanbanColumnModel(
      id: doc.id,
      tenantId: data['tenant_id'] ?? '',
      title: data['title'] ?? '',
      colorValue: data['color'] ?? Colors.blue.value,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'color': colorValue,
      'order': order,
    };
  }
}
