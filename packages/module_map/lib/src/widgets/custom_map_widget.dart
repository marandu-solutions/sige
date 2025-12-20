import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_point_model.dart';

class CustomMapWidget extends StatefulWidget {
  final List<MapPointModel> points;
  final CameraPosition initialCameraPosition;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(MapPointModel)? onPointTap;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;

  const CustomMapWidget({
    super.key,
    this.points = const [],
    this.initialCameraPosition = const CameraPosition(
      target: LatLng(-23.550520, -46.633308), // São Paulo default
      zoom: 12,
    ),
    this.onMapCreated,
    this.onTap,
    this.onPointTap,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
  });

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(CustomMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points != oldWidget.points) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers = widget.points.map((point) {
        return Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(
            title: point.title,
            snippet: point.description,
          ),
          onTap: () {
            widget.onPointTap?.call(point);
          },
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      markers: _markers,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      onTap: widget.onTap,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      mapToolbarEnabled: true,
      zoomControlsEnabled: true,
    );
  }
}
