import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_map/src/controllers/map_controller.dart';
import 'package:module_map/src/models/map_point_model.dart';
import 'package:module_map/src/widgets/custom_map_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // We can start checking permissions early, but we need the controller to move the camera.
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Serviços de localização estão desativados.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Permissões de localização permanentemente negadas.')),
        );
      }
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final position = await Geolocator.getCurrentPosition();

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interativo'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () {
              ref.read(mapControllerProvider.notifier).clearPoints();
            },
            tooltip: 'Limpar Pontos',
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomMapWidget(
            points: mapState.points,
            onMapCreated: (controller) {
              _mapController = controller;
              // Automatically go to current location when map is created
              _goToCurrentLocation();
            },
            onTap: (latLng) {
              _showAddPointDialog(context, latLng);
            },
            onPointTap: (point) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ponto selecionado: ${point.title}')),
              );
            },
          ),
          if (mapState.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        child: const Icon(LucideIcons.crosshair),
      ),
    );
  }

  void _showAddPointDialog(BuildContext context, LatLng latLng) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Ponto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 8),
            Text('Lat: ${latLng.latitude.toStringAsFixed(4)}'),
            Text('Lng: ${latLng.longitude.toStringAsFixed(4)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final point = MapPointModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text.isEmpty
                    ? 'Novo Ponto'
                    : titleController.text,
                description: descController.text,
                latitude: latLng.latitude,
                longitude: latLng.longitude,
                type: 'custom',
              );
              ref.read(mapControllerProvider.notifier).addPoint(point);
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
