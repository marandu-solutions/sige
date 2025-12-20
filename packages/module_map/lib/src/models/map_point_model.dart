class MapPointModel {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String? type; // e.g., 'imovel', 'loja', etc.

  MapPointModel({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.type,
  });

  MapPointModel copyWith({
    String? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? type,
  }) {
    return MapPointModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
    );
  }
}
