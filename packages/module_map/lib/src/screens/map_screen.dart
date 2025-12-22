import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

import 'package:module_map/src/controllers/map_controller.dart';
import 'package:module_map/src/models/map_point_model.dart';
import 'package:module_map/src/models/map_polygon_model.dart';

// --- Map Style Definition ---
enum MapTheme { dark, light, satellite }

class MapStyle {
  final String id;
  final String name;
  final String urlTemplate;
  final MapTheme theme;
  final IconData icon;

  const MapStyle({
    required this.id,
    required this.name,
    required this.urlTemplate,
    required this.theme,
    required this.icon,
  });
}

// Available Styles
const List<MapStyle> kMapStyles = [
  MapStyle(
    id: 'dark',
    name: 'Dark Matter',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    theme: MapTheme.dark,
    icon: LucideIcons.moon,
  ),
  MapStyle(
    id: 'light',
    name: 'Positron',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    theme: MapTheme.light,
    icon: LucideIcons.sun,
  ),
  MapStyle(
    id: 'voyager',
    name: 'Voyager',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    theme: MapTheme.light,
    icon: LucideIcons.map,
  ),
  MapStyle(
    id: 'satellite',
    name: 'Satélite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    theme: MapTheme.satellite,
    icon: LucideIcons.globe,
  ),
];

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _flutterMapController; // The one for the widget
  MapStyle _currentStyle = kMapStyles[0];

  final ValueNotifier<LatLng?> _mousePosition = ValueNotifier(null);
  final ValueNotifier<MapPolygonModel?> _hoveredPolygon = ValueNotifier(null);
  final ValueNotifier<Offset?> _tooltipPosition = ValueNotifier(null);

  @override
  void dispose() {
    _mousePosition.dispose();
    _hoveredPolygon.dispose();
    _tooltipPosition.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _flutterMapController = MapController(); // Flutter Map's controller

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).fetchCityMesh('2403608');
    });
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    _flutterMapController.move(
        LatLng(position.latitude, position.longitude), 15);
  }

  Color _getPolygonColor() {
    switch (_currentStyle.theme) {
      case MapTheme.dark:
      case MapTheme.satellite:
        return const Color(0xFF00BFA5); // Teal bright for dark bg
      case MapTheme.light:
        return const Color(0xFF00695C); // Teal dark for light bg
    }
  }

  Future<void> _handleCreatePolygon() async {
    final points = ref.read(mapControllerProvider).drawingPoints;

    if (points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Um polígono precisa de pelo menos 3 pontos.')),
      );
      return;
    }

    await _showPolygonDialog(points: points);
  }

  Future<void> _showPolygonDialog(
      {required List<LatLng> points, MapPolygonModel? existingPolygon}) async {
    final controller = ref.read(mapControllerProvider.notifier);
    final nameController =
        TextEditingController(text: existingPolygon?.name ?? '');
    final attributes =
        Map<String, dynamic>.from(existingPolygon?.attributes ?? {});
    final attributeTypes =
        Map<String, AttributeType>.from(existingPolygon?.attributeTypes ?? {});

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a1a),
              title: Text(
                  existingPolygon == null ? 'Novo Polígono' : 'Editar Polígono',
                  style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nome do Polígono',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Atributos',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...attributes.entries.map((entry) {
                        return ListTile(
                          title: Text(entry.key,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${entry.value}',
                              style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                attributes.remove(entry.key);
                                attributeTypes.remove(entry.key);
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.plus),
                        label: const Text('Adicionar Atributo'),
                        onPressed: () async {
                          await _showAddAttributeDialog(context,
                              (key, value, type) {
                            setState(() {
                              attributes[key] = value;
                              attributeTypes[key] = type;
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (existingPolygon != null)
                  TextButton(
                    onPressed: () {
                      controller.deleteCustomPolygon(existingPolygon.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Polígono excluído com sucesso!')),
                      );
                    },
                    child: const Text('Excluir',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                TextButton(
                  onPressed: () {
                    if (existingPolygon == null) {
                      controller.cancelDrawing();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;

                    final newPolygon = MapPolygonModel(
                      id: existingPolygon?.id ?? const Uuid().v4(),
                      name: nameController.text,
                      points: List.from(points),
                      attributes: attributes,
                      attributeTypes: attributeTypes,
                    );

                    controller.saveCustomPolygon(newPolygon);
                    if (existingPolygon == null) {
                      controller.cancelDrawing();
                    }
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Polígono salvo com sucesso!')),
                    );
                  },
                  child: const Text('Salvar',
                      style: TextStyle(color: Color(0xFF00BFA5))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddAttributeDialog(BuildContext context,
      Function(String, dynamic, AttributeType) onAdd) async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    AttributeType selectedType = AttributeType.text;
    bool boolValue = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2a2a2a),
              title: const Text('Adicionar Atributo',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome do Atributo',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<AttributeType>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF2a2a2a),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: AttributeType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child:
                            Text(type.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (selectedType == AttributeType.boolean)
                    SwitchListTile(
                      title: const Text('Valor',
                          style: TextStyle(color: Colors.white)),
                      value: boolValue,
                      onChanged: (val) => setState(() => boolValue = val),
                    )
                  else
                    TextField(
                      controller: valueController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: selectedType == AttributeType.number
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;

                    dynamic finalValue;
                    if (selectedType == AttributeType.boolean) {
                      finalValue = boolValue;
                    } else if (selectedType == AttributeType.number) {
                      finalValue = num.tryParse(valueController.text) ?? 0;
                    } else {
                      finalValue = valueController.text;
                    }

                    onAdd(nameController.text, finalValue, selectedType);
                    Navigator.pop(context);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    final polygonBaseColor = _getPolygonColor();

    ref.listen(mapControllerProvider, (previous, next) {
      if (next.isExtremozSelected && !previous!.isExtremozSelected) {
        if (next.meshBounds != null) {
          _flutterMapController.fitCamera(
            CameraFit.bounds(
              bounds: next.meshBounds!,
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      }

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          MouseRegion(
            onHover: (event) {
              if (mapState.isDrawingMode) {
                final point = _flutterMapController.camera.pointToLatLng(
                    math.Point(event.localPosition.dx, event.localPosition.dy));
                _mousePosition.value = point;
              } else {
                _mousePosition.value = null;
              }

              if (!mapState.isDrawingMode) {
                final point = _flutterMapController.camera.pointToLatLng(
                    math.Point(event.localPosition.dx, event.localPosition.dy));

                final controller = ref.read(mapControllerProvider.notifier);
                MapPolygonModel? found;
                for (var poly in mapState.customPolygons) {
                  if (controller.isPointInPolygon(point, poly.points)) {
                    found = poly;
                    break;
                  }
                }
                _hoveredPolygon.value = found;
                _tooltipPosition.value = event.localPosition;
              } else {
                _hoveredPolygon.value = null;
              }
            },
            child: FlutterMap(
              mapController: _flutterMapController,
              options: MapOptions(
                initialCenter:
                    const LatLng(-5.81, -36.6), // Center of RN approx
                initialZoom: 8.5, // Zoom to see whole state
                backgroundColor: _currentStyle.theme == MapTheme.light
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF1a1a1a),
                onTap: (tapPosition, point) {
                  final controller = ref.read(mapControllerProvider.notifier);
                  if (mapState.isDrawingMode) {
                    if (mapState.drawingPoints.length >= 3) {
                      final firstPoint = mapState.drawingPoints.first;
                      final screenFirst = _flutterMapController.camera
                          .latLngToScreenPoint(firstPoint);
                      final screenTap = tapPosition.relative!;

                      final dist = (screenFirst.x - screenTap.dx).abs() +
                          (screenFirst.y - screenTap.dy).abs();
                      if (dist < 20) {
                        _handleCreatePolygon();
                        return;
                      }
                    }
                    controller.handleTap(point);
                  } else {
                    MapPolygonModel? clickedPoly;
                    for (var poly in mapState.customPolygons) {
                      if (controller.isPointInPolygon(point, poly.points)) {
                        clickedPoly = poly;
                        break;
                      }
                    }
                    if (clickedPoly != null) {
                      _showPolygonDialog(
                          points: clickedPoly.points,
                          existingPolygon: clickedPoly);
                    } else {
                      controller.handleTap(point);
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _currentStyle.urlTemplate,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.sige.app',
                ),

                // Extremoz Mesh (Only visible if NOT selected)
                if (!mapState.isExtremozSelected)
                  PolygonLayer(
                    polygons: mapState.polygons.map((polygon) {
                      return Polygon(
                        points: polygon.points,
                        color: polygonBaseColor.withOpacity(0.15),
                        borderColor: polygonBaseColor.withOpacity(0.8),
                        borderStrokeWidth: 2,
                        isFilled: true,
                      );
                    }).toList(),
                  ),

                // Custom User Polygons (Saved)
                PolygonLayer(
                  polygons: mapState.customPolygons.map((poly) {
                    return Polygon(
                      points: poly.points,
                      color: Colors.purple.withOpacity(0.2),
                      borderColor: Colors.purpleAccent,
                      borderStrokeWidth: 2,
                      isFilled: true,
                      label: poly.name,
                      labelStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),

                // Current Drawing Polygon (Preview)
                if (mapState.isDrawingMode && mapState.drawingPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          ...mapState.drawingPoints,
                        ],
                        color: const Color(0xFF00BFA5),
                        strokeWidth: 3,
                      ),
                    ],
                  ),

                // Rubber band line
                if (mapState.isDrawingMode && mapState.drawingPoints.isNotEmpty)
                  ValueListenableBuilder<LatLng?>(
                    valueListenable: _mousePosition,
                    builder: (context, mousePos, _) {
                      if (mousePos == null) return const SizedBox.shrink();

                      return PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [mapState.drawingPoints.last, mousePos],
                            color: const Color(0xFF00BFA5).withOpacity(0.5),
                            strokeWidth: 2,
                            isDotted: true,
                          ),
                          if (mapState.drawingPoints.length >= 2)
                            Polyline(
                              points: [mousePos, mapState.drawingPoints.first],
                              color: Colors.white.withOpacity(0.3),
                              strokeWidth: 1,
                              isDotted: true,
                            )
                        ],
                      );
                    },
                  ),

                // Drawing Points Markers
                if (mapState.isDrawingMode)
                  MarkerLayer(
                    markers: mapState.drawingPoints
                        .map((p) => Marker(
                              point: p,
                              width: 10,
                              height: 10,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                // First point highlight
                if (mapState.isDrawingMode && mapState.drawingPoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: mapState.drawingPoints.first,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF00BFA5), width: 2),
                          ),
                        ),
                      )
                    ],
                  ),

                MarkerLayer(
                  markers: mapState.points.map((point) {
                    return Marker(
                      point: LatLng(point.latitude, point.longitude),
                      width: 200,
                      height: 80,
                      child: _buildRichMarker(point),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 2. Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildGlassPanel(
              child: Row(
                children: [
                  const Icon(LucideIcons.map, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SIGE GeoIntelligence',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.search, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Action Controls
          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              children: [
                _buildGlassIconButton(
                  icon: LucideIcons.layers,
                  onTap: () => _showMapStyleSelector(context),
                  tooltip: 'Camadas',
                ),
                const SizedBox(height: 12),
                _buildGlassIconButton(
                  icon: mapState.isDrawingMode
                      ? LucideIcons.check
                      : LucideIcons.penTool,
                  onTap: () {
                    if (mapState.isDrawingMode) {
                      _handleCreatePolygon();
                    } else {
                      ref
                          .read(mapControllerProvider.notifier)
                          .toggleDrawingMode();
                    }
                  },
                  tooltip: mapState.isDrawingMode
                      ? 'Finalizar Polígono'
                      : 'Criar Polígono',
                ),
                if (mapState.isDrawingMode) ...[
                  const SizedBox(height: 8),
                  _buildGlassIconButton(
                    icon: LucideIcons.x,
                    onTap: () {
                      ref.read(mapControllerProvider.notifier).cancelDrawing();
                    },
                    tooltip: 'Cancelar Desenho',
                  ),
                ],
                const SizedBox(height: 12),
                _buildGlassIconButton(
                  icon: LucideIcons.crosshair,
                  onTap: _goToCurrentLocation,
                  tooltip: 'Minha Localização',
                ),
                const SizedBox(height: 12),
                _buildGlassIconButton(
                  icon: LucideIcons.plus,
                  onTap: () {
                    final currentZoom = _flutterMapController.camera.zoom;
                    _flutterMapController.move(
                        _flutterMapController.camera.center, currentZoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _buildGlassIconButton(
                  icon: LucideIcons.minus,
                  onTap: () {
                    final currentZoom = _flutterMapController.camera.zoom;
                    _flutterMapController.move(
                        _flutterMapController.camera.center, currentZoom - 1);
                  },
                ),
              ],
            ),
          ),

          // 4. Loading Indicator
          if (mapState.isLoading)
            Positioned(
              bottom: 40,
              left: 20,
              child: _buildGlassPanel(
                child: const Row(
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Carregando dados...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

          // 5. Instruction Banner (Drawing Mode)
          if (mapState.isDrawingMode)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Center(
                child: _buildGlassPanel(
                  child: const Text(
                    'Toque no mapa para adicionar pontos. Clique no "Check" ou no primeiro ponto para finalizar.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Tooltip Layer
          ValueListenableBuilder<MapPolygonModel?>(
            valueListenable: _hoveredPolygon,
            builder: (context, hovered, _) {
              if (hovered == null) return const SizedBox.shrink();

              return ValueListenableBuilder<Offset?>(
                valueListenable: _tooltipPosition,
                builder: (context, pos, _) {
                  if (pos == null) return const SizedBox.shrink();

                  return Positioned(
                    left: pos.dx + 15,
                    top: pos.dy - 15,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hovered.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            if (hovered.attributes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...hovered.attributes.entries.take(3).map((e) =>
                                  Text(
                                      '${e.key}: ${e.value}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)))
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMapStyleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a).withOpacity(0.9),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estilo do Mapa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kMapStyles.map((style) {
                        final isSelected = _currentStyle.id == style.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentStyle = style;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF00BFA5)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00BFA5)
                                                  .withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Icon(
                                    style.icon,
                                    color: isSelected
                                        ? const Color(0xFF00BFA5)
                                        : Colors.white70,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  style.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF00BFA5)
                                        : Colors.white70,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black
                .withOpacity(0.6), // Slightly darker for better contrast
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassIconButton(
      {required IconData icon, required VoidCallback onTap, String? tooltip}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: Tooltip(
            message: tooltip ?? '',
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: 48, // Slightly larger touch target
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichMarker(MapPointModel point) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassPanel(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.home, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(
                point.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 2,
          height: 10,
          color: Colors.white.withOpacity(0.8),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
      ],
    );
  }
}
