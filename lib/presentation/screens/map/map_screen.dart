import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../core/di/injection.dart';
import '../../blocs/weather/weather_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 5.0;
  LatLng _currentCenter = const LatLng(36.0, 138.0);

  String? _rainviewerPath;
  final DateTime _currentTime = DateTime.now();

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
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(const LoadWeather()),
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
                  _buildRainOverlay(),
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
    );
  }

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
          // Title
          const Text(
            'Rain Radar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          // Color legend bar
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
          // Gradient bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF80D8FF), // light blue
                  Color(0xFF448AFF), // blue
                  Color(0xFF2962FF), // dark blue
                  Color(0xFF1A237E), // navy
                  Color(0xFFFFEB3B), // yellow
                  Color(0xFFFF9800), // orange
                  Color(0xFFFF5722), // red-orange
                  Color(0xFFF44336), // red
                  Color(0xFFE91E63), // pink
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Scale values
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
          // Now label + time + layer icon
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
              // Layer toggle
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.layers,
                  color: Color(0xFF00BCD4),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time ticks
          _buildTimeTicks(now),
        ],
      ),
    );
  }

  Widget _buildTimeTicks(DateTime now) {
    final startMinute = (now.minute ~/ 10 * 10) - 30;
    final startTime = DateTime(now.year, now.month, now.day, now.hour, 0)
        .add(Duration(minutes: startMinute));

    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(13, (index) {
          final tickTime = startTime.add(Duration(minutes: index * 5));
          final isCurrentTick = tickTime.hour == now.hour &&
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
    return const SizedBox.shrink();
  }
}
