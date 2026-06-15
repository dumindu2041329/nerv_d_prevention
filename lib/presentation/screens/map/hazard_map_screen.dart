import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sl_constants.dart';

enum _HazardTab { rain, landslide, flooding, inundation }

/// Severity levels shown in the hazard map legend.
enum _Severity { advisory, caution, danger, emergency }

extension _SeverityX on _Severity {
  Color get color {
    switch (this) {
      case _Severity.advisory:
        return const Color(0xFFFFC400);
      case _Severity.caution:
        return const Color(0xFFFF1744);
      case _Severity.danger:
        return const Color(0xFFE91E63);
      case _Severity.emergency:
        return const Color(0xFFAA00FF);
    }
  }

  String get label {
    switch (this) {
      case _Severity.advisory:
        return 'Advisory';
      case _Severity.caution:
        return 'Caution';
      case _Severity.danger:
        return 'Danger';
      case _Severity.emergency:
        return 'Emergency';
    }
  }
}

class _HazardPoint {
  final LatLng location;
  final _Severity severity;
  const _HazardPoint(this.location, this.severity);
}

/// Mock risk area data for Sri Lanka districts, grouped by hazard type.
const Map<_HazardTab, List<_HazardPoint>> _hazardData = {
  _HazardTab.rain: [],
  _HazardTab.landslide: [
    _HazardPoint(LatLng(6.9497, 80.7891), _Severity.advisory), // Nuwara Eliya
    _HazardPoint(LatLng(6.9820, 80.7800), _Severity.advisory),
    _HazardPoint(LatLng(7.2906, 80.6337), _Severity.advisory), // Kandy
    _HazardPoint(LatLng(6.9897, 81.0557), _Severity.advisory), // Badulla
    _HazardPoint(LatLng(6.6828, 80.3994), _Severity.advisory), // Ratnapura
    _HazardPoint(LatLng(7.2539, 80.3535), _Severity.advisory), // Kegalle
    _HazardPoint(LatLng(7.4675, 80.6234), _Severity.caution),  // Matale
    _HazardPoint(LatLng(6.8728, 81.3507), _Severity.advisory), // Monaragala
  ],
  _HazardTab.flooding: [
    _HazardPoint(LatLng(6.9271, 79.8612), _Severity.advisory), // Colombo
    _HazardPoint(LatLng(7.0867, 80.0128), _Severity.advisory), // Gampaha
    _HazardPoint(LatLng(6.5854, 79.9607), _Severity.advisory), // Kalutara
    _HazardPoint(LatLng(8.0362, 79.8287), _Severity.advisory), // Puttalam
    _HazardPoint(LatLng(7.4875, 80.3647), _Severity.caution),  // Kurunegala
    _HazardPoint(LatLng(7.7167, 81.7000), _Severity.caution),  // Batticaloa
    _HazardPoint(LatLng(7.2833, 81.6667), _Severity.caution),  // Ampara
    _HazardPoint(LatLng(6.0535, 80.2210), _Severity.danger),   // Galle
    _HazardPoint(LatLng(6.7100, 79.9500), _Severity.danger),
  ],
  _HazardTab.inundation: [
    _HazardPoint(LatLng(9.6683, 80.0074), _Severity.advisory), // Jaffna
    _HazardPoint(LatLng(8.9802, 79.9043), _Severity.advisory), // Mannar
    _HazardPoint(LatLng(8.0362, 79.8287), _Severity.advisory), // Puttalam
    _HazardPoint(LatLng(6.9271, 79.8612), _Severity.advisory), // Colombo
    _HazardPoint(LatLng(6.0535, 80.2210), _Severity.advisory), // Galle
    _HazardPoint(LatLng(5.9485, 80.5353), _Severity.advisory), // Matara
    _HazardPoint(LatLng(6.1241, 81.1185), _Severity.caution),  // Hambantota
    _HazardPoint(LatLng(7.7167, 81.7000), _Severity.caution),  // Batticaloa
  ],
};

class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  _HazardTab _tab = _HazardTab.rain;
  final MapController _mapController = MapController();
  late String _displayedTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String get _title {
    switch (_tab) {
      case _HazardTab.rain:
        return 'Rainfall Analysis';
      case _HazardTab.landslide:
        return 'Landslide Risk Area';
      case _HazardTab.flooding:
        return 'Flood Warning Risk Area';
      case _HazardTab.inundation:
        return 'Inundation Risk Area';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen dark map background
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: SLMapConstants.center,
                initialZoom: SLMapConstants.initialZoom,
                minZoom: SLMapConstants.minZoom,
                maxZoom: SLMapConstants.maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: ApiConstants.mapTileHybrid,
                  userAgentPackageName: 'com.example.nerv_d_prevention',
                ),
                if (_tab == _HazardTab.rain)
                  TileLayer(
                    urlTemplate: ApiConstants.owmPrecipitationOverlay,
                    userAgentPackageName: 'com.example.nerv_d_prevention',
                    tileDisplay:
                        const TileDisplay.instantaneous(opacity: 0.85),
                  ),
                _buildRiskLayer(),
              ],
            ),
          ),

          // Top: Title + Legend
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(context),
          ),

          // Bottom: Sub-tab bar + time + layers button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  // ── Risk Layer ──────────────────────────────────────────────────────

  Widget _buildRiskLayer() {
    final points = _hazardData[_tab] ?? const [];
    if (points.isEmpty) return const SizedBox.shrink();
    return CircleLayer(
      circles: points.map((p) {
        return CircleMarker(
          point: p.location,
          radius: 7,
          useRadiusInMeter: false,
          color: p.severity.color.withValues(alpha: 0.9),
          borderColor: p.severity.color,
          borderStrokeWidth: 1.5,
        );
      }).toList(),
    );
  }

  // ── Top Overlay ─────────────────────────────────────────────────────

  Widget _buildTopOverlay(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (_tab == _HazardTab.rain)
            _buildRainfallScale()
          else
            _buildSeverityLegend(),
        ],
      ),
    );
  }

  Widget _buildSeverityLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _Severity.values.length; i++) ...[
            _legendDot(_Severity.values[i]),
            const SizedBox(width: 6),
            Text(
              _Severity.values[i].label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (i != _Severity.values.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(_Severity s) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: s == _Severity.emergency
            ? Colors.transparent
            : s.color.withValues(alpha: 0.9),
        border: Border.all(color: s.color, width: 1.5),
      ),
    );
  }

  Widget _buildRainfallScale() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF80D8FF),
                  Color(0xFF448AFF),
                  Color(0xFF2962FF),
                  Color(0xFF1A237E),
                  Color(0xFFFFEB3B),
                  Color(0xFFFF9800),
                  Color(0xFFFF5722),
                  Color(0xFFF44336),
                  Color(0xFFE91E63),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final v in const ['1', '5', '10', '20', '30', '50', '80'])
                Text(
                  v,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                '(mm/h)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: bottomPadding + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time display (bottom-left)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Text(
              _displayedTime,
              style: const TextStyle(
                color: Color(0xFF00BCD4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sub-tab pills
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subTab(_HazardTab.rain, 'Rain'),
                  _subTab(_HazardTab.landslide, 'Landslide'),
                  _subTab(_HazardTab.flooding, 'Flooding'),
                  _subTab(_HazardTab.inundation, 'Inundation'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Layers button
          InkResponse(
            onTap: () => Navigator.of(context).maybePop(),
            radius: 24,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.layers,
                color: Color(0xFF00BCD4),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subTab(_HazardTab tab, String label) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00BCD4).withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00BCD4)
                  : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF00BCD4) : Colors.white,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
