import 'package:latlong2/latlong.dart';

enum AttributeType { text, number, boolean }

class MapPolygonModel {
  final String id;
  final String name;
  final List<LatLng> points;
  final Map<String, dynamic> attributes;
  final Map<String, AttributeType> attributeTypes;

  MapPolygonModel({
    required this.id,
    required this.name,
    required this.points,
    this.attributes = const {},
    this.attributeTypes = const {},
  });

  MapPolygonModel copyWith({
    String? id,
    String? name,
    List<LatLng>? points,
    Map<String, dynamic>? attributes,
    Map<String, AttributeType>? attributeTypes,
  }) {
    return MapPolygonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      attributes: attributes ?? this.attributes,
      attributeTypes: attributeTypes ?? this.attributeTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'attributes': attributes,
      'attributeTypes': attributeTypes.map((key, value) => MapEntry(key, value.index)),
    };
  }

  factory MapPolygonModel.fromJson(Map<String, dynamic> json) {
    return MapPolygonModel(
      id: json['id'],
      name: json['name'],
      points: (json['points'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      attributes: Map<String, dynamic>.from(json['attributes']),
      attributeTypes: (json['attributeTypes'] as Map).map(
        (key, value) => MapEntry(key, AttributeType.values[value]),
      ),
    );
  }
}
