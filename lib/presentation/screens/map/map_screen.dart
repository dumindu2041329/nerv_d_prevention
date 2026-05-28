import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../blocs/weather/weather_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = SLMapConstants.initialZoom;
  LatLng _currentCenter = SLMapConstants.center;
  LatLng? _gpsLocation;
  final DateTime _currentTime = DateTime.now();

  void _zoomToMyLocation() {
    final target = _gpsLocation ?? SLMapConstants.center;
    _mapController.move(target, 12.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(const LoadWeather()),
      child: BlocListener<WeatherBloc, WeatherState>(
        listener: (context, state) {
          if (state is WeatherLoaded && state.location != null) {
            final loc = state.location!;
            final newLatLng = LatLng(loc.latitude, loc.longitude);
            if (_gpsLocation == null) {
              setState(() {
                _gpsLocation = newLatLng;
                _currentCenter = newLatLng;
              });
              _mapController.move(newLatLng, 12.0);
            } else if (_gpsLocation != newLatLng) {
              setState(() {
                _gpsLocation = newLatLng;
              });
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full-screen map
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: _currentZoom,
                    minZoom: SLMapConstants.minZoom,
                    maxZoom: SLMapConstants.maxZoom,
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
                    // Base: satellite-hybrid
                    TileLayer(
                      urlTemplate: ApiConstants.mapTileHybrid,
                      userAgentPackageName: 'com.example.nerv_d_prevention',
                    ),
                    // Precipitation overlay
                    TileLayer(
                      urlTemplate: ApiConstants.owmPrecipitationOverlay,
                      userAgentPackageName: 'com.example.nerv_d_prevention',
                      tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
                    ),
                    RichAttributionWidget(
                      animationConfig: const ScaleRAWA(),
                      attributions: [
                        TextSourceAttribution(
                          '© OpenStreetMap contributors',
                          onTap: () => {},
                        ),
                        TextSourceAttribution('© MapTiler', onTap: () => {}),
                      ],
                    ),
                    _buildUserLocationMarker(),
                  ],
                ),
              ),

              // Top: Title + Color Legend
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(context),
              ),

              // Weather chip (floating, top-left below title)
              Positioned(
                left: 16,
                top: MediaQuery.of(context).padding.top + 80,
                child: _buildWeatherChip(context),
              ),

              // My Location button
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 80,
                child: _buildMapButton(Icons.my_location, _zoomToMyLocation),
              ),

              // Bottom: Time Scrubber
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildTimeScrubber(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── User Location Marker ────────────────────────────────────────────

  Widget _buildUserLocationMarker() {
    if (_gpsLocation == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          width: 36,
          height: 36,
          point: _gpsLocation!,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              // Inner dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00BCD4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Weather Chip ────────────────────────────────────────────────────

  Widget _buildWeatherChip(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is WeatherLoaded) {
          final current = state.weatherData.current;
          final emoji = WeatherCodeMapping.getIcon(current.weatherCode);
          final locationName = state.location?.name ?? 'Current Location';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E29).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${current.temperature.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      locationName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Map Controls ────────────────────────────────────────────────────

  Widget _buildMapButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E29),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
      ),
    );
  }

  // ── Top Overlay ─────────────────────────────────────────────────────

  Widget _buildTopOverlay(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Weather Map — Sri Lanka',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildColorLegend(),
        ],
      ),
    );
  }

  Widget _buildColorLegend() {
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
              _buildLegendLabel('1'),
              _buildLegendLabel('5'),
              _buildLegendLabel('10'),
              _buildLegendLabel('20'),
              _buildLegendLabel('30'),
              _buildLegendLabel('50'),
              _buildLegendLabel('80'),
              _buildLegendLabel('(mm/h)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTimeScrubber(BuildContext context) {
    final now = _currentTime;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = (now.minute ~/ 10 * 10).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 60),
              const Text(
                'Now',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$hour:$minute',
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              const Icon(Icons.layers, color: Color(0xFF00BCD4), size: 28),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeTicks(now),
        ],
      ),
    );
  }

  Widget _buildTimeTicks(DateTime now) {
    final startMinute = (now.minute ~/ 10 * 10) - 30;
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      0,
    ).add(Duration(minutes: startMinute));

    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(13, (index) {
          final tickTime = startTime.add(Duration(minutes: index * 5));
          final isCurrentTick =
              tickTime.hour == now.hour &&
              (tickTime.minute ~/ 10) == (now.minute ~/ 10);
          final showLabel = index % 2 == 0;

          return Expanded(
            child: Column(
              children: [
                if (showLabel)
                  Text(
                    '${tickTime.hour.toString().padLeft(2, '0')}:${tickTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  )
                else
                  const SizedBox(height: 12),
                const SizedBox(height: 2),
                Container(
                  width: isCurrentTick ? 4 : 2,
                  height: isCurrentTick ? 18 : 14,
                  decoration: BoxDecoration(
                    color: isCurrentTick
                        ? const Color(0xFF00BCD4)
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
