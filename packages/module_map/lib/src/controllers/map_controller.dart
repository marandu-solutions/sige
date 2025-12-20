import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/map_point_model.dart';

class MapState {
  final List<MapPointModel> points;
  final bool isLoading;

  MapState({
    this.points = const [],
    this.isLoading = false,
  });

  MapState copyWith({
    List<MapPointModel>? points,
    bool? isLoading,
  }) {
    return MapState(
      points: points ?? this.points,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MapController extends StateNotifier<MapState> {
  MapController() : super(MapState());

  void addPoint(MapPointModel point) {
    state = state.copyWith(points: [...state.points, point]);
  }

  void removePoint(String id) {
    state = state.copyWith(
      points: state.points.where((p) => p.id != id).toList(),
    );
  }

  void updatePoint(MapPointModel point) {
    state = state.copyWith(
      points: state.points.map((p) => p.id == point.id ? point : p).toList(),
    );
  }

  void clearPoints() {
    state = state.copyWith(points: []);
  }
}

final mapControllerProvider = StateNotifierProvider<MapController, MapState>((ref) {
  return MapController();
});
