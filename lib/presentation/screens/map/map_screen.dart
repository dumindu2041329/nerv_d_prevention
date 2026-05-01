import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/constants.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/location.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/location_search_widget.dart';

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
  
  String? _rainviewerPath;

  final List<String> _layers = ['none', 'rain', 'hazard', 'wind', 'temp'];

  @override
  void initState() {
    super.initState();
    _fetchRainviewerData();
  }

  Future<void> _fetchRainviewerData() async {
    try {
      final response = await Dio().get('https://api.rainviewer.com/public/weather-maps.json');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['radar'] != null && data['radar']['past'] != null) {
          final past = data['radar']['past'] as List;
          if (past.isNotEmpty) {
            setState(() {
              _rainviewerPath = past.last['path'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load Rainviewer data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(const LoadWeather()),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
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
                  if (hasGesture) {
                    setState(() {
                      _currentCenter = position.center;
                      _currentZoom = position.zoom;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.nerv_d_prevention',
                ),
                _buildOverlayLayer(),
              ],
            ),
            
            // Floating Location Buttons
            Positioned(
              right: AppSpacing.space4,
              bottom: 120, // Keep above the bottom chips
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapButton(
                    context: context,
                    icon: Icons.layers,
                    onTap: () => _showLayerSelector(context),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildMapButton(
                    context: context,
                    icon: Icons.my_location,
                    onTap: _centerOnCurrentLocation,
                  ),
                ],
              ),
            ),
            
            // Bottom Layer Chips
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildLayerChips(context),
            ),
            
            // Top Floating Search Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.space4,
              left: AppSpacing.space4,
              right: AppSpacing.space4,
              child: Builder(
                builder: (BuildContext innerContext) => _buildFloatingSearchBar(innerContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<WeatherBloc>();
    
    return GestureDetector(
      onTap: () {
        LocationSearchWidget.showSearchSheet(context, bloc, (location) {
          _centerOnLocation(location);
          bloc.add(SelectLocation(location: location));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                'Search location...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Icon(Icons.tune, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerChips(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        top: AppSpacing.space4,
        bottom: AppSpacing.space4 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.5),
            width: 1,
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
                showCheckmark: false,
                label: Text(_getLayerLabel(layer)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedLayer = layer);
                  }
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  side: BorderSide(
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOverlayLayer() {
    if (_selectedLayer == 'none') {
      return CircleLayer<CircleMarker<Object>>(circles: const []);
    }
    
    switch (_selectedLayer) {
      case 'rain':
        return _buildRainOverlay();
      case 'wind':
        return _buildTemporaryOverlay(Colors.green);
      case 'temp':
        return _buildTemporaryOverlay(Colors.orange);
      case 'hazard':
        return _buildTemporaryOverlay(Colors.red);
      default:
        return CircleLayer<CircleMarker<Object>>(circles: const []);
    }
  }

  Widget _buildRainOverlay() {
    if (_rainviewerPath != null) {
      return Opacity(
        opacity: 0.6,
        child: TileLayer(
          urlTemplate: 'https://tilecache.rainviewer.com{path}/256/{z}/{x}/{y}/2/1_1.png',
          additionalOptions: {
            'path': _rainviewerPath!,
          },
        ),
      );
    }
    // Fallback if data not yet loaded or failed
    return const SizedBox.shrink();
  }

  Widget _buildTemporaryOverlay(Color color) {
    // Placeholder for other non-implemented layers
    return CircleLayer(
      circles: [
        CircleMarker(
          point: _currentCenter,
          radius: 100,
          color: color.withValues(alpha: 0.15),
          borderColor: color,
          borderStrokeWidth: 1,
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required BuildContext context,
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
            color: theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
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
      case 'none':
        return 'None';
      case 'rain':
        return 'Rain Radar';
      case 'hazard':
        return 'Hazard Zones';
      case 'wind':
        return 'Wind Speed';
      case 'temp':
        return 'Temperature';
      default:
        return layer.toUpperCase();
    }
  }

  void _centerOnCurrentLocation() {
    setState(() {
      _currentCenter = const LatLng(6.9271, 79.8612); // Mock current location
      _currentZoom = 12.0;
    });
    _mapController.move(_currentCenter, _currentZoom);
  }

  void _centerOnLocation(Location location) {
    setState(() {
      _currentCenter = LatLng(location.latitude, location.longitude);
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
      case 'none':
        return Icons.layers_clear;
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
