import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String _selectedLayer = 'rain';
  double _currentZoom = 10.0;
  LatLng _currentCenter = const LatLng(6.9271, 79.8612);

  final List<String> _layers = ['rain', 'hazard', 'wind', 'temp'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              minZoom: 3,
              maxZoom: 18,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentCenter = position.center!;
                    if (position.zoom != null) {
                      _currentZoom = position.zoom!;
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nerv_d_prevention',
              ),
              _buildOverlayLayer(),
            ],
          ),
          Positioned(
            right: AppSpacing.space4,
            bottom: 120,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.layers,
                  onTap: () => _showLayerSelector(context),
                ),
                const SizedBox(height: AppSpacing.space2),
                _buildMapButton(
                  icon: Icons.my_location,
                  onTap: _centerOnCurrentLocation,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: theme.dividerTheme.color ?? Colors.grey,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _layers.map((layer) {
                    final isSelected = layer == _selectedLayer;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.space2),
                      child: ChoiceChip(
                        label: Text(_getLayerLabel(layer)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedLayer = layer);
                          }
                        },
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayLayer() {
    switch (_selectedLayer) {
      case 'rain':
        return _buildRainOverlay();
      case 'wind':
        return _buildWindOverlay();
      case 'temp':
        return _buildTempOverlay();
      default:
        return CircleLayer<CircleMarker<Object>>(circles: const []);
    }
  }

  Widget _buildRainOverlay() {
    return CircleLayer(
      circles: [
        CircleMarker(
          point: _currentCenter,
          radius: 50,
          color: Colors.blue.withValues(alpha: 0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        ),
        CircleMarker(
          point: LatLng(_currentCenter.latitude + 0.1, _currentCenter.longitude + 0.1),
          radius: 40,
          color: Colors.cyan.withValues(alpha: 0.3),
          borderColor: Colors.cyan,
          borderStrokeWidth: 2,
        ),
        CircleMarker(
          point: LatLng(_currentCenter.latitude - 0.05, _currentCenter.longitude + 0.15),
          radius: 30,
          color: Colors.yellow.withValues(alpha: 0.3),
          borderColor: Colors.yellow,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  Widget _buildWindOverlay() {
    return CircleLayer(
      circles: [
        CircleMarker(
          point: _currentCenter,
          radius: 60,
          color: Colors.green.withValues(alpha: 0.2),
          borderColor: Colors.green,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  Widget _buildTempOverlay() {
    return CircleLayer(
      circles: [
        CircleMarker(
          point: _currentCenter,
          radius: 50,
          color: Colors.orange.withValues(alpha: 0.3),
          borderColor: Colors.orange,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: theme.dividerTheme.color ?? Colors.grey,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }

  String _getLayerLabel(String layer) {
    switch (layer) {
      case 'rain':
        return 'Rain';
      case 'hazard':
        return 'Hazard';
      case 'wind':
        return 'Wind';
      case 'temp':
        return 'Temp';
      default:
        return layer;
    }
  }

  void _centerOnCurrentLocation() {
    setState(() {
      _currentCenter = const LatLng(6.9271, 79.8612);
      _currentZoom = 12.0;
    });
    _mapController.move(_currentCenter, _currentZoom);
  }

  void _showLayerSelector(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Map Layers',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              ..._layers.map((layer) {
                return ListTile(
                  leading: Icon(
                    _getLayerIcon(layer),
                    color: layer == _selectedLayer
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  title: Text(_getLayerLabel(layer)),
                  trailing: layer == _selectedLayer
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedLayer = layer);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getLayerIcon(String layer) {
    switch (layer) {
      case 'rain':
        return Icons.water_drop;
      case 'hazard':
        return Icons.warning;
      case 'wind':
        return Icons.air;
      case 'temp':
        return Icons.thermostat;
      default:
        return Icons.layers;
    }
  }
}

class MapLayerData {
  final String id;
  final String label;
  final String labelEn;
  final IconData icon;

  const MapLayerData({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.icon,
  });
}
