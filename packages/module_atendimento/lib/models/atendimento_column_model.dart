import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AtendimentoColumnModel {
  final String id;
  final String tenantId;
  final String title;
  final int colorValue;
  final int order;

  AtendimentoColumnModel({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.colorValue,
    required this.order,
  });

  Color get color => Color(colorValue);

  /// Converte um DocumentSnapshot do Firestore para um objeto AtendimentoColumnModel.
  factory AtendimentoColumnModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AtendimentoColumnModel.fromMap(data, doc.id);
  }

  /// Converte um Map para AtendimentoColumnModel
  factory AtendimentoColumnModel.fromMap(Map<String, dynamic> map,
      [String? id]) {
    return AtendimentoColumnModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      title: map['title'] ?? '',
      colorValue: map['color_value'] ?? 4280391411, // Cor padrão azul
      order: map['order'] ?? 0,
    );
  }

  /// Converte o objeto AtendimentoColumnModel para um Map compatível com Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'color_value': colorValue,
      'order': order,
    };
  }

  AtendimentoColumnModel copyWith({
    String? id,
    String? tenantId,
    String? title,
    int? colorValue,
    int? order,
  }) {
    return AtendimentoColumnModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
      order: order ?? this.order,
    );
  }
}
