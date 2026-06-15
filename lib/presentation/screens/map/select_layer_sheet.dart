import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Identifies the overlay/visual layer rendered on top of the map.
enum MapLayer {
  rainRadar,
  hazardMap,
  river,
  typhoon,
  realTimeWeather,
  snow,
  weatherForecast,
  lightning,
  strongMotionMonitor,
  crisisMapping,
}

extension MapLayerX on MapLayer {
  /// OWM tile URL for the overlay drawn on top of the base map.
  /// Returns `null` when no tile overlay should be drawn for this layer.
  String? get overlayUrl {
    switch (this) {
      case MapLayer.rainRadar:
        return ApiConstants.owmPrecipitationOverlay;
      case MapLayer.realTimeWeather:
        return ApiConstants.owmTempOverlay;
      case MapLayer.snow:
        return ApiConstants.owmSnowOverlay;
      case MapLayer.weatherForecast:
        return ApiConstants.owmCloudsOverlay;
      case MapLayer.typhoon:
        return ApiConstants.owmWindOverlay;
      case MapLayer.lightning:
        return ApiConstants.owmPressureOverlay;
      case MapLayer.hazardMap:
      case MapLayer.river:
      case MapLayer.strongMotionMonitor:
      case MapLayer.crisisMapping:
        return null;
    }
  }

  /// Display title shown on the map's top overlay when this layer is active.
  String get mapTitle {
    switch (this) {
      case MapLayer.rainRadar:
        return 'Rain Radar';
      case MapLayer.hazardMap:
        return 'Hazard Map';
      case MapLayer.river:
        return 'River Watch';
      case MapLayer.typhoon:
        return 'Typhoon Tracker';
      case MapLayer.realTimeWeather:
        return 'Real-Time Weather';
      case MapLayer.snow:
        return 'Snow Cover';
      case MapLayer.weatherForecast:
        return 'Weather Forecast';
      case MapLayer.lightning:
        return 'Lightning';
      case MapLayer.strongMotionMonitor:
        return 'Strong-Motion Monitor';
      case MapLayer.crisisMapping:
        return 'Crisis Mapping';
    }
  }
}

class SelectLayerSheet extends StatefulWidget {
  final MapLayer initialLayer;
  final ValueChanged<MapLayer> onLayerChanged;

  const SelectLayerSheet({
    super.key,
    this.initialLayer = MapLayer.rainRadar,
    required this.onLayerChanged,
  });

  @override
  State<SelectLayerSheet> createState() => _SelectLayerSheetState();
}

class _SelectLayerSheetState extends State<SelectLayerSheet> {
  late MapLayer _selected = widget.initialLayer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0B0B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0x1FFFFFFF),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _layers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final layer = _layers[index];
                  return _LayerTile(
                    layer: layer,
                    selected: _selected == layer.id,
                    onTap: () {
                      setState(() => _selected = layer.id);
                      widget.onLayerChanged(layer.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          const Text(
            'Select Layer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 22,
            ),
            splashRadius: 22,
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close,
              color: Colors.white.withValues(alpha: 0.85),
              size: 24,
            ),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  static const List<_LayerDescriptor> _layers = [
    _LayerDescriptor(
      id: MapLayer.rainRadar,
      label: 'Rain Radar',
      icon: Icons.umbrella_outlined,
    ),
    _LayerDescriptor(
      id: MapLayer.hazardMap,
      label: 'Hazard Map',
      icon: Icons.warning_amber_rounded,
    ),
    _LayerDescriptor(
      id: MapLayer.river,
      label: 'River',
      icon: Icons.waves,
    ),
    _LayerDescriptor(
      id: MapLayer.typhoon,
      label: 'Typhoon',
      icon: Icons.cyclone,
    ),
    _LayerDescriptor(
      id: MapLayer.realTimeWeather,
      label: 'Real-Time Weather',
      icon: Icons.cloud_outlined,
    ),
    _LayerDescriptor(
      id: MapLayer.snow,
      label: 'Snow',
      icon: Icons.ac_unit,
    ),
    _LayerDescriptor(
      id: MapLayer.weatherForecast,
      label: 'Weather Forecast',
      icon: Icons.wb_cloudy_outlined,
    ),
    _LayerDescriptor(
      id: MapLayer.lightning,
      label: 'Lightning',
      icon: Icons.bolt_outlined,
    ),
    _LayerDescriptor(
      id: MapLayer.strongMotionMonitor,
      label: 'Strong-Motion Monitor',
      icon: Icons.monitor_heart_outlined,
    ),
    _LayerDescriptor(
      id: MapLayer.crisisMapping,
      label: 'Crisis Mapping',
      icon: Icons.map_outlined,
    ),
  ];
}

class _LayerDescriptor {
  final MapLayer id;
  final String label;
  final IconData icon;

  const _LayerDescriptor({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class _LayerTile extends StatelessWidget {
  final _LayerDescriptor layer;
  final bool selected;
  final VoidCallback onTap;

  const _LayerTile({
    required this.layer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF00BCD4)
        : Colors.white.withValues(alpha: 0.85);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(layer.icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              layer.label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
