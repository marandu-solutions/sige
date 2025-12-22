import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_point_model.dart';
import '../models/map_polygon_model.dart';

class MapState {
  final List<MapPointModel> points;
  final List<Polygon> polygons; // For rendering
  final List<MapPolygonModel> customPolygons; // For data
  final bool isLoading;
  final String? errorMessage;
  final LatLngBounds? meshBounds;
  final bool isExtremozSelected;
  final bool isDrawingMode;
  final List<LatLng> drawingPoints;

  MapState({
    this.points = const [],
    this.polygons = const [],
    this.customPolygons = const [],
    this.isLoading = false,
    this.errorMessage,
    this.meshBounds,
    this.isExtremozSelected = false,
    this.isDrawingMode = false,
    this.drawingPoints = const [],
  });

  MapState copyWith({
    List<MapPointModel>? points,
    List<Polygon>? polygons,
    List<MapPolygonModel>? customPolygons,
    bool? isLoading,
    String? errorMessage,
    LatLngBounds? meshBounds,
    bool? isExtremozSelected,
    bool? isDrawingMode,
    List<LatLng>? drawingPoints,
  }) {
    return MapState(
      points: points ?? this.points,
      polygons: polygons ?? this.polygons,
      customPolygons: customPolygons ?? this.customPolygons,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      meshBounds: meshBounds ?? this.meshBounds,
      isExtremozSelected: isExtremozSelected ?? this.isExtremozSelected,
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      drawingPoints: drawingPoints ?? this.drawingPoints,
    );
  }
}

class MapFeatureController extends StateNotifier<MapState> {
  MapFeatureController() : super(MapState()) {
    _loadCustomPolygons();
  }

  static const String _storageKey = 'custom_polygons';

  Future<void> _loadCustomPolygons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_storageKey);
      if (stored != null) {
        final List<dynamic> list = json.decode(stored);
        final polygons = list.map((e) => MapPolygonModel.fromJson(e)).toList();
        state = state.copyWith(customPolygons: polygons);
      }
    } catch (e) {
      print('Error loading custom polygons: $e');
    }
  }

  Future<void> saveCustomPolygon(MapPolygonModel polygon) async {
    final index = state.customPolygons.indexWhere((p) => p.id == polygon.id);
    List<MapPolygonModel> updatedList;
    if (index >= 0) {
      updatedList = List.from(state.customPolygons);
      updatedList[index] = polygon;
    } else {
      updatedList = [...state.customPolygons, polygon];
    }
    state = state.copyWith(customPolygons: updatedList);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String data =
          json.encode(updatedList.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      print('Error saving custom polygons: $e');
    }
  }

  Future<void> deleteCustomPolygon(String id) async {
    final updatedList = state.customPolygons.where((p) => p.id != id).toList();
    state = state.copyWith(customPolygons: updatedList);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String data =
          json.encode(updatedList.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      print('Error deleting custom polygons: $e');
    }
  }

  void addPoint(MapPointModel point) {
    state = state.copyWith(points: [...state.points, point]);
  }

  void toggleDrawingMode() {
    state = state.copyWith(
      isDrawingMode: !state.isDrawingMode,
      drawingPoints: [], // Clear when toggling
    );
  }

  void addDrawingPoint(LatLng point) {
    if (!state.isDrawingMode) return;
    state = state.copyWith(drawingPoints: [...state.drawingPoints, point]);
  }

  void clearDrawing() {
    state = state.copyWith(drawingPoints: []);
  }

  void cancelDrawing() {
    state = state.copyWith(
      isDrawingMode: false,
      drawingPoints: [],
    );
  }

  void handleTap(LatLng point) {
    if (state.isDrawingMode) {
      addDrawingPoint(point);
    } else {
      // Check if inside Extremoz mesh (if not already selected)
      if (!state.isExtremozSelected && state.polygons.isNotEmpty) {
        // Simplified check: Check if point is inside ANY of the loaded mesh polygons
        bool isInside = false;
        for (var polygon in state.polygons) {
          if (isPointInPolygon(point, polygon.points)) {
            isInside = true;
            break;
          }
        }

        if (isInside) {
          state = state.copyWith(isExtremozSelected: true);
        }
      }
    }
  }

  // Ray-casting algorithm
  bool isPointInPolygon(LatLng point, List<LatLng> polygonPoints) {
    bool isInside = false;
    int j = polygonPoints.length - 1;
    for (int i = 0; i < polygonPoints.length; i++) {
      if (((polygonPoints[i].latitude > point.latitude) !=
              (polygonPoints[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygonPoints[j].longitude - polygonPoints[i].longitude) *
                      (point.latitude - polygonPoints[i].latitude) /
                      (polygonPoints[j].latitude - polygonPoints[i].latitude) +
                  polygonPoints[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  Future<void> fetchCityMesh(String ibgeCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final url = Uri.parse(
          'https://servicodados.ibge.gov.br/api/v3/malhas/municipios/$ibgeCode?formato=application/vnd.geo+json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Polygon> loadedPolygons = [];

        // Calculate bounds
        double? minLat, maxLat, minLng, maxLng;

        void updateBounds(LatLng point) {
          if (minLat == null || point.latitude < minLat!)
            minLat = point.latitude;
          if (maxLat == null || point.latitude > maxLat!)
            maxLat = point.latitude;
          if (minLng == null || point.longitude < minLng!)
            minLng = point.longitude;
          if (maxLng == null || point.longitude > maxLng!)
            maxLng = point.longitude;
        }

        void processPolygon(List<dynamic> coordinates) {
          if (coordinates.isEmpty) return;
          final List<LatLng> points = [];
          for (var point in coordinates[0]) {
            final latLng = LatLng(point[1].toDouble(), point[0].toDouble());
            points.add(latLng);
            updateBounds(latLng);
          }
          loadedPolygons.add(Polygon(
            points: points,
            color: Colors.blue.withOpacity(0.15),
            borderColor: Colors.blue.withOpacity(0.6),
            borderStrokeWidth: 2,
            isFilled: true,
          ));
        }

        void parseFeature(Map<String, dynamic> feature) {
          final geometry = feature['geometry'];
          if (geometry == null) return;

          if (geometry['type'] == 'Polygon') {
            processPolygon(geometry['coordinates']);
          } else if (geometry['type'] == 'MultiPolygon') {
            for (var polygonCoords in geometry['coordinates']) {
              processPolygon(polygonCoords);
            }
          }
        }

        if (data['type'] == 'FeatureCollection') {
          for (var feature in data['features']) {
            parseFeature(feature);
          }
        } else if (data['type'] == 'Feature') {
          parseFeature(data);
        }

        LatLngBounds? bounds;
        if (minLat != null &&
            maxLat != null &&
            minLng != null &&
            maxLng != null) {
          bounds = LatLngBounds(
            LatLng(minLat!, minLng!),
            LatLng(maxLat!, maxLng!),
          );
        }

        state = state.copyWith(
          polygons: loadedPolygons,
          isLoading: false,
          meshBounds: bounds,
        );
      } else {
        print('Error fetching mesh: ${response.statusCode}');
        state = state.copyWith(
            isLoading: false,
            errorMessage: 'Erro ao carregar malha: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mesh: $e');
      state =
          state.copyWith(isLoading: false, errorMessage: 'Erro de conexão: $e');
    }
  }
}

final mapControllerProvider =
    StateNotifierProvider<MapFeatureController, MapState>((ref) {
  return MapFeatureController();
});
