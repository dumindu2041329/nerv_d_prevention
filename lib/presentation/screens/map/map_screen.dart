import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/weather_data.dart';
import '../../blocs/weather/weather_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const int _minutesStep = 5;

  final MapController _mapController = MapController();
  late final WeatherBloc _weatherBloc;
  double _currentZoom = SLMapConstants.initialZoom;
  LatLng _currentCenter = SLMapConstants.center;
  LatLng? _gpsLocation;
  int _selectedSlotIndex = 0;
  double _dragAccumulator = 0;

  @override
  void initState() {
    super.initState();
    _weatherBloc = getIt<WeatherBloc>()..add(const LoadWeather(useGps: true));
  }

  @override
  void dispose() {
    _weatherBloc.close();
    super.dispose();
  }

  void _zoomToMyLocation() {
    final target = _gpsLocation ?? SLMapConstants.center;
    _mapController.move(target, 12.0);
  }

  /// Expands the hourly forecast into 5-minute slots via linear interpolation
  /// between adjacent hours. Returns 12*12 + 1 = 145 slots spanning 12 hours.
  /// The last hour is anchored by the first hour of the next day if present.
  List<_FiveMinSlot> _buildFiveMinSlots(List<HourlyWeather> hourly) {
    if (hourly.isEmpty) return const [];

    // Anchor with a synthetic "previous hour" at time[0] - 1h so the first
    // 5-minute step of the first real hour has a partner to interpolate from.
    final base = <_FiveMinSlot>[];
    final firstTime = hourly.first.time;
    final prevTime = firstTime.subtract(const Duration(hours: 1));
    final prevTemp = hourly.first.temperature;
    final prevPrecip = hourly.first.precipitation;
    final prevPop = hourly.first.precipitationProbability;
    final prevWind = hourly.first.windSpeed;
    final prevGust = hourly.first.windGusts;
    final prevUv = hourly.first.uvIndex;
    final prevHum = hourly.first.humidity;

    for (int i = 0; i < hourly.length; i++) {
      final curr = hourly[i];
      _FiveMinSlot? next;
      if (i + 1 < hourly.length) {
        final n = hourly[i + 1];
        next = _FiveMinSlot(
          time: n.time,
          temperature: n.temperature,
          precipitation: n.precipitation,
          precipitationProbability: n.precipitationProbability,
          windSpeed: n.windSpeed,
          windGusts: n.windGusts,
          weatherCode: n.weatherCode,
          uvIndex: n.uvIndex,
          humidity: n.humidity,
        );
      }

      // 12 sub-slots stepping from the previous anchor to this hour (inclusive)
      _FiveMinSlot anchor;
      if (i == 0) {
        anchor = _FiveMinSlot(
          time: prevTime,
          temperature: prevTemp,
          precipitation: prevPrecip,
          precipitationProbability: prevPop,
          windSpeed: prevWind,
          windGusts: prevGust,
          weatherCode: curr.weatherCode,
          uvIndex: prevUv,
          humidity: prevHum,
        );
      } else {
        anchor = _FiveMinSlot(
          time: hourly[i - 1].time,
          temperature: hourly[i - 1].temperature,
          precipitation: hourly[i - 1].precipitation,
          precipitationProbability: hourly[i - 1].precipitationProbability,
          windSpeed: hourly[i - 1].windSpeed,
          windGusts: hourly[i - 1].windGusts,
          weatherCode: curr.weatherCode,
          uvIndex: hourly[i - 1].uvIndex,
          humidity: hourly[i - 1].humidity,
        );
      }

      final start = anchor.time;
      final end = curr.time;
      final totalMinutes = end.difference(start).inMinutes.clamp(1, 60);
      final steps = (totalMinutes / _minutesStep).floor();

      for (int s = 0; s < steps; s++) {
        final t = s / steps;
        base.add(_FiveMinSlot(
          time: start.add(Duration(minutes: s * _minutesStep)),
          temperature: _lerp(anchor.temperature, curr.temperature, t),
          precipitation: _lerp(anchor.precipitation, curr.precipitation, t),
          precipitationProbability:
              _lerp(anchor.precipitationProbability, curr.precipitationProbability, t),
          windSpeed: _lerp(anchor.windSpeed, curr.windSpeed, t),
          windGusts: _lerp(anchor.windGusts, curr.windGusts, t),
          weatherCode: curr.weatherCode,
          uvIndex: _lerp(anchor.uvIndex, curr.uvIndex, t),
          humidity: _lerp(anchor.humidity, curr.humidity, t),
        ));
      }

      // Always include the exact hour mark.
      base.add(_FiveMinSlot(
        time: curr.time,
        temperature: curr.temperature,
        precipitation: curr.precipitation,
        precipitationProbability: curr.precipitationProbability,
        windSpeed: curr.windSpeed,
        windGusts: curr.windGusts,
        weatherCode: curr.weatherCode,
        uvIndex: curr.uvIndex,
        humidity: curr.humidity,
      ));

      // If no next hour to anchor to, stop after 12 hours total.
      if (next == null) break;
    }

    return base;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _weatherBloc,
      child: BlocListener<WeatherBloc, WeatherState>(
        listener: (context, state) {
          if (state is WeatherLoaded && state.location != null) {
            final loc = state.location!;
            final newLatLng = LatLng(loc.latitude, loc.longitude);
            if (_gpsLocation == null) {
              setState(() {
                _gpsLocation = newLatLng;
                _currentCenter = newLatLng;
                _selectedSlotIndex = 0;
              });
              _mapController.move(newLatLng, 12.0);
            } else if (_gpsLocation != newLatLng) {
              setState(() {
                _gpsLocation = newLatLng;
                _selectedSlotIndex = 0;
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
          final slots = _buildFiveMinSlots(state.weatherData.hourly);
          final selectedIndex = _clampIndex(_selectedSlotIndex, slots.length);
          final selected = slots.isNotEmpty ? slots[selectedIndex] : null;

          final weatherCode = selected?.weatherCode ?? state.weatherData.current.weatherCode;
          final temp = selected?.temperature ?? state.weatherData.current.temperature;
          final time = selected?.time ?? state.weatherData.current.time;
          final emoji = WeatherCodeMapping.getIcon(weatherCode, isDay: _isDay(time));
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
                      '${temp.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$locationName · ${DateTimeUtils.formatTime(time)}',
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
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final slots = state is WeatherLoaded
            ? _buildFiveMinSlots(state.weatherData.hourly)
            : const <_FiveMinSlot>[];

        final selectedIndex = _clampIndex(_selectedSlotIndex, slots.length);
        final selectedTime =
            slots.isNotEmpty ? slots[selectedIndex].time : DateTime.now();
        final isNow =
            selectedTime.difference(DateTime.now()).abs().inMinutes <= 30;

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomPadding + 16,
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
                  Text(
                    isNow ? 'Now · UTC' : '${DateTimeUtils.formatDateUtc(selectedTime)} · UTC',
                    style: const TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    DateTimeUtils.formatTimeUtc(selectedTime),
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
              const SizedBox(height: 10),
              if (slots.length > 1)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: const Color(0xFF00BCD4),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
                    thumbColor: const Color(0xFF00BCD4),
                    overlayColor: const Color(0xFF00BCD4).withValues(alpha: 0.18),
                    thumbShape: const _ScrubberThumbShape(),
                  ),
                  child: Slider(
                    value: selectedIndex.toDouble(),
                    min: 0,
                    max: (slots.length - 1).toDouble(),
                    divisions: slots.length - 1,
                    onChanged: (v) {
                      setState(() => _selectedSlotIndex = v.round());
                    },
                  ),
                )
              else
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(height: 8),
              if (slots.isNotEmpty)
                _buildSlotTicks(slots, selectedIndex)
              else
                _buildTimeTicksSkeleton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeTicksSkeleton() {
    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(13, (index) {
          final showLabel = index % 2 == 0;

          return Expanded(
            child: Column(
              children: [
                if (showLabel)
                  Text(
                    '--:--',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 10,
                    ),
                  )
                else
                  const SizedBox(height: 12),
                const SizedBox(height: 2),
                Container(
                  width: 2,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
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

  Widget _buildSlotTicks(List<_FiveMinSlot> slots, int selectedIndex) {
    final count = slots.length;
    if (count == 0) return _buildTimeTicksSkeleton();

    final windowSize = count < 25 ? count : 25;
    final half = windowSize ~/ 2;
    final maxStart = (count - windowSize).clamp(0, count);
    var startIndex = (selectedIndex - half).clamp(0, maxStart);
    var endIndex = startIndex + windowSize;
    if (endIndex > count) {
      endIndex = count;
      startIndex = (endIndex - windowSize).clamp(0, maxStart);
    }

    void setIndex(int index) {
      setState(() => _selectedSlotIndex = index.clamp(0, count - 1));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final dx = details.localPosition.dx.clamp(0, constraints.maxWidth);
            if (constraints.maxWidth <= 0) return;
            final ratio = dx / constraints.maxWidth;
            final idxInWindow =
                (ratio * windowSize).floor().clamp(0, windowSize - 1);
            setIndex(startIndex + idxInWindow);
          },
          onHorizontalDragStart: (_) => _dragAccumulator = 0,
          onHorizontalDragUpdate: (details) {
            final delta = details.primaryDelta ?? 0;
            _dragAccumulator += delta;
            const stepPx = 6.0;
            final steps = (_dragAccumulator / stepPx).truncate();
            if (steps != 0) {
              _dragAccumulator -= steps * stepPx;
              setIndex(selectedIndex + steps);
            }
          },
          onHorizontalDragEnd: (_) => _dragAccumulator = 0,
          child: SizedBox(
            height: 36,
            child: Row(
              children: [
                for (int i = startIndex; i < endIndex; i++)
                  Expanded(
                    child: Column(
                      children: [
                        if ((i - startIndex) % 6 == 0)
                          Text(
                            DateTimeUtils.formatTimeUtc(slots[i].time),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 2),
                        Container(
                          width: i == selectedIndex ? 4 : 2,
                          height: i == selectedIndex ? 18 : 14,
                          decoration: BoxDecoration(
                            color:
                                i == selectedIndex
                                    ? const Color(0xFF00BCD4)
                                    : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _clampIndex(int index, int length) {
    if (length <= 0) return 0;
    return index.clamp(0, length - 1);
  }

  bool _isDay(DateTime time) => time.hour >= 6 && time.hour < 18;
}

class _FiveMinSlot {
  final DateTime time;
  final double temperature;
  final double precipitation;
  final double precipitationProbability;
  final double windSpeed;
  final double windGusts;
  final int weatherCode;
  final double uvIndex;
  final double humidity;

  const _FiveMinSlot({
    required this.time,
    required this.temperature,
    required this.precipitation,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.windGusts,
    required this.weatherCode,
    required this.uvIndex,
    required this.humidity,
  });
}

class _ScrubberThumbShape extends SliderComponentShape {
  const _ScrubberThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(10, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint =
        Paint()
          ..color = sliderTheme.thumbColor ?? const Color(0xFF00BCD4)
          ..style = PaintingStyle.fill;
    final rect = Rect.fromCenter(center: center, width: 4, height: 22);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1.5));
    context.canvas.drawRRect(rrect, paint);
  }
}
