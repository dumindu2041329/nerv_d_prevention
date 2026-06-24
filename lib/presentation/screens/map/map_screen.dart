import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/repositories/landslide_repository.dart';
import '../../../domain/entities/weather_data.dart';
import '../../blocs/weather/weather_bloc.dart';
import 'select_layer_sheet.dart';

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
  MapLayer _selectedLayer = MapLayer.rainRadar;
  _HazardTab _hazardTab = _HazardTab.rain;
  late String _hazardDisplayedTime;
  List<_HazardPoint> _landslidePoints = const [];
  List<_LandslidePolygonItem> _landslidePolygons = const [];
  bool _landslideLoading = false;

  @override
  void initState() {
    super.initState();
    _weatherBloc = getIt<WeatherBloc>()..add(const LoadWeather(useGps: true));
    final now = DateTime.now();
    _hazardDisplayedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

  Future<void> _fetchLandslides() async {
    if (_landslideLoading) return;
    setState(() => _landslideLoading = true);
    final repo = getIt<LandslideRepository>();
    final zones = await repo.getActiveZones();
    if (!mounted) return;
    setState(() {
      _landslideLoading = false;
      _landslidePoints = zones
          .where((z) => z.isPoint || !z.isPolygon)
          .map((z) => _HazardPoint(
                LatLng(z.latitude!, z.longitude!),
                _severityFromString(z.severity),
              ))
          .toList();
      _landslidePolygons = zones
          .where((z) => z.isPolygon)
          .map((z) => _LandslidePolygonItem(
                z.polygonRings!
                    .map((p) => LatLng(p[0], p[1]))
                    .toList(),
                _severityFromString(z.severity),
                z.name,
                z.source,
              ))
          .toList();
    });
  }

  String get _hazardTitle {
    switch (_hazardTab) {
      case _HazardTab.rain:
        return 'Rainfall Analysis';
      case _HazardTab.landslide:
        return 'Landslide Risk Area';
    }
  }

  void _openLayerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SelectLayerSheet(
          initialLayer: _selectedLayer,
          onLayerChanged: (layer) {
            if (_selectedLayer == layer) return;
            setState(() => _selectedLayer = layer);
            // Load landslide risk areas the first time hazard map opens.
            if (layer == MapLayer.hazardMap && _landslidePoints.isEmpty) {
              _fetchLandslides();
            }
            // Re-fetch weather so the chip and time scrubber reflect the
            // freshly-loaded data for the new layer.
            _weatherBloc.add(
              const LoadWeather(useGps: true, forceRefresh: true),
            );
          },
        );
      },
    );
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
    final theme = Theme.of(context);
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
          backgroundColor: theme.scaffoldBackgroundColor,
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
                    // Crop vertical whitespace so the map's top edge never
                    // exceeds the Arctic (90°N) and the bottom edge never
                    // exceeds Antarctica (-90°S). These are the defaults
                    // of `containLatitude`, and they're the exact reason
                    // this helper exists ("prevent the background color
                    // from appearing at the 'top' and 'bottom' of the
                    // typical map"). Horizontal panning stays free.
                    cameraConstraint:
                        CameraConstraint.containLatitude(),
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
                    // Layer-specific overlay (reactive to selected layer)
                    if (_selectedLayer == MapLayer.hazardMap &&
                        _hazardTab == _HazardTab.rain)
                      TileLayer(
                        urlTemplate: ApiConstants.owmPrecipitationOverlay,
                        userAgentPackageName: 'com.example.nerv_d_prevention',
                        tileDisplay: const TileDisplay.instantaneous(opacity: 0.85),
                      )
                    else if (_selectedLayer.overlayUrl != null)
                      TileLayer(
                        urlTemplate: _selectedLayer.overlayUrl!,
                        userAgentPackageName: 'com.example.nerv_d_prevention',
                        tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
                      ),
                    // Hazard risk circles (only when hazard layer is active)
                    if (_selectedLayer == MapLayer.hazardMap)
                      _buildHazardRiskLayer(),
                    // Layer-specific markers/visualizations
                    _buildLayerMarkers(),
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
                    if (_selectedLayer != MapLayer.hazardMap)
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

              // Weather chip (floating, top-left below title) — hidden in hazard mode
              if (_selectedLayer != MapLayer.hazardMap)
                Positioned(
                  left: 16,
                  top: MediaQuery.of(context).padding.top + 80,
                  child: _buildWeatherChip(context),
                ),

              // My Location button — hidden in hazard mode
              if (_selectedLayer != MapLayer.hazardMap)
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 80,
                  child: _buildMapButton(Icons.my_location, _zoomToMyLocation),
                ),

              // Bottom: Time Scrubber (or Hazard sub-tabs in hazard mode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _selectedLayer == MapLayer.hazardMap
                    ? _buildHazardBottomBar(context)
                    : _buildTimeScrubber(context),
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
    final primary = Theme.of(context).colorScheme.primary;
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
                  color: primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
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
                  color: primary,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.5),
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

  // ── Layer Markers (per MapLayer) ────────────────────────────────────

  /// Returns a MarkerLayer that visualises the active layer's data on the
  /// map. Reads the most recent weather snapshot from WeatherBloc.
  Widget _buildLayerMarkers() {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is! WeatherLoaded) return const SizedBox.shrink();
        if (_gpsLocation == null) return const SizedBox.shrink();

        final current = state.weatherData.current;
        final hourly = state.weatherData.hourly;
        final marker = _markerForLayer(
          layer: _selectedLayer,
          current: current,
          hourly: hourly,
          locationName: state.location?.name ?? 'Current Location',
        );
        if (marker == null) return const SizedBox.shrink();

        return MarkerLayer(
          markers: [
            Marker(
              width: 140,
              height: 70,
              point: _gpsLocation!,
              alignment: Alignment.bottomCenter,
              child: marker,
            ),
          ],
        );
      },
    );
  }

  Widget? _markerForLayer({
    required MapLayer layer,
    required CurrentWeather current,
    required List<HourlyWeather> hourly,
    required String locationName,
  }) {
    final emoji = WeatherCodeMapping.getIcon(
      current.weatherCode,
      isDay: _isDay(current.time),
    );
    final tempC = current.temperature.toStringAsFixed(0);
    final windKph = current.windSpeed.toStringAsFixed(0);
    final humidityPct = current.humidity.toStringAsFixed(0);

    switch (layer) {
      case MapLayer.realTimeWeather:
        return _WeatherPin(
          color: const Color(0xFF00BCD4),
          emoji: emoji,
          primary: '$tempC°C',
          secondary: '$locationName · $windKph km/h',
        );
      case MapLayer.snow:
        final snowyHours = hourly
            .where((h) =>
                h.precipitation > 0 &&
                h.temperature <= 2.0 &&
                (h.weatherCode == 1210 ||
                    h.weatherCode == 1213 ||
                    h.weatherCode == 1216 ||
                    h.weatherCode == 1219 ||
                    h.weatherCode == 1222 ||
                    h.weatherCode == 1225 ||
                    h.weatherCode == 1255 ||
                    h.weatherCode == 1258))
            .length;
        return _WeatherPin(
          color: const Color(0xFF80D8FF),
          emoji: '❄️',
          primary: snowyHours > 0 ? '$snowyHours h snow' : 'No snow',
          secondary: 'Feels ${current.apparentTemperature.toStringAsFixed(0)}°C',
        );
      case MapLayer.weatherForecast:
        final next = hourly.isNotEmpty ? hourly.first : null;
        final nextEmoji = next == null
            ? emoji
            : WeatherCodeMapping.getIcon(next.weatherCode, isDay: _isDay(next.time));
        return _WeatherPin(
          color: const Color(0xFFFFC400),
          emoji: nextEmoji,
          primary: next == null
              ? '$tempC°C'
              : '${next.temperature.toStringAsFixed(0)}°C',
          secondary: next == null
              ? 'No forecast'
              : 'Next hr · ${(next.precipitationProbability).toStringAsFixed(0)}%',
        );
      case MapLayer.typhoon:
        return _WeatherPin(
          color: const Color(0xFFFF6D00),
          emoji: '🌀',
          primary: '$windKph km/h',
          secondary: 'Wind · $humidityPct% RH',
        );
      case MapLayer.lightning:
        final thunderRisk = hourly
            .where((h) =>
                h.precipitationProbability >= 60 &&
                h.weatherCode >= 1273 &&
                h.weatherCode <= 1282)
            .length;
        return _WeatherPin(
          color: const Color(0xFFFFC400),
          emoji: '⚡',
          primary: thunderRisk > 0 ? '$thunderRisk h risk' : 'Calm',
          secondary: 'Pressure ${current.surfacePressure.toStringAsFixed(0)} hPa',
        );
      case MapLayer.hazardMap:
        return _WeatherPin(
          color: const Color(0xFFFF1744),
          emoji: '⚠️',
          primary: 'Hazard scan',
          secondary: 'Wind $windKph · $humidityPct% RH',
        );
      case MapLayer.crisisMapping:
        return _WeatherPin(
          color: const Color(0xFF69F0AE),
          emoji: '🆘',
          primary: 'Crisis monitor',
          secondary: 'Local · $tempC°C',
        );
      case MapLayer.strongMotionMonitor:
        return _WeatherPin(
          color: const Color(0xFFFF1744),
          emoji: '📈',
          primary: 'Seismic',
          secondary: 'Local baseline',
        );
      case MapLayer.river:
        final rainMm = current.precipitation.toStringAsFixed(1);
        return _WeatherPin(
          color: const Color(0xFF42A5F5),
          emoji: '🌊',
          primary: '$rainMm mm',
          secondary: 'Rainfall · $humidityPct% RH',
        );
      case MapLayer.rainRadar:
        return null;
    }
  }

  // ── Weather Chip ────────────────────────────────────────────────────

  Widget _buildWeatherChip(BuildContext context) {
    final theme = Theme.of(context);
    final chipBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1E29).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.96);
    final chipBorder = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final primaryText = theme.colorScheme.onSurface;
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is WeatherLoaded) {
          final slots = _buildFiveMinSlots(state.weatherData.hourly);
          final selectedIndex = _clampIndex(_selectedSlotIndex, slots.length);
          final selected = slots.isNotEmpty ? slots[selectedIndex] : null;

          final weatherCode =
              selected?.weatherCode ?? state.weatherData.current.weatherCode;
          final temp =
              selected?.temperature ?? state.weatherData.current.temperature;
          final time = selected?.time ?? state.weatherData.current.time;
          final emoji =
              WeatherCodeMapping.getIcon(weatherCode, isDay: _isDay(time));
          final locationName = state.location?.name ?? 'Current Location';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: chipBorder, width: 1),
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
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$locationName · ${DateTimeUtils.formatTime(time)}',
                      style: TextStyle(
                        color: primaryText.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1E29)
        : Colors.white.withValues(alpha: 0.96);
    final border = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          size: 24,
        ),
      ),
    );
  }

  // ── Top Overlay ─────────────────────────────────────────────────────

  Widget _buildTopOverlay(BuildContext context) {
    final isHazard = _selectedLayer == MapLayer.hazardMap;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final overlayBg = Theme.of(context).brightness == Brightness.dark
        ? [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ]
        : [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.6),
            Colors.transparent,
          ];
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: overlayBg,
        ),
      ),
      child: Column(
        children: [
          Text(
            isHazard ? _hazardTitle : _selectedLayer.mapTitle,
            style: TextStyle(
              color: onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (isHazard && _hazardTab == _HazardTab.rain)
            _buildHazardRainfallScale()
          else if (_selectedLayer == MapLayer.rainRadar)
            _buildColorLegend(),
        ],
      ),
    );
  }

  Widget _buildHazardRainfallScale() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
                    color: onSurface.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                '(mm/h)',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ── Hazard Map UI ───────────────────────────────────────────────────

  Widget _buildHazardRiskLayer() {
    if (_hazardTab != _HazardTab.landslide) return const SizedBox.shrink();
    return Stack(
      children: [
        if (_landslidePolygons.isNotEmpty)
          PolygonLayer(
            polygons: _landslidePolygons
                .map((p) => Polygon(
                      points: p.ring,
                      color: p.severity.color.withValues(alpha: 0.22),
                      borderColor: p.severity.color.withValues(alpha: 0.85),
                      borderStrokeWidth: 1.5,
                      label: p.name,
                      labelStyle: TextStyle(
                        color: p.severity.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
            polygonLabels: true,
          ),
        if (_landslidePoints.isNotEmpty)
          CircleLayer(
            circles: _landslidePoints.map((p) {
              return CircleMarker(
                point: p.location,
                radius: 7,
                useRadiusInMeter: false,
                color: p.severity.color.withValues(alpha: 0.9),
                borderColor: p.severity.color,
                borderStrokeWidth: 1.5,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHazardBottomBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final barBg = isDark
        ? Colors.black.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.94);
    final barBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final pillIdleBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: bottomPadding + 12,
      ),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: barBorder, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time display (bottom-left)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pillIdleBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: barBorder, width: 0.5),
            ),
            child: Text(
              _hazardDisplayedTime,
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
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
                  _hazardSubTab(_HazardTab.rain, 'Rain'),
                  _hazardSubTab(_HazardTab.landslide, 'Landslide'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Layers button — opens the layer sheet so the user can switch back
          InkResponse(
            onTap: _openLayerSheet,
            radius: 24,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primary.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Icon(Icons.layers, color: primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hazardSubTab(_HazardTab tab, String label) {
    final selected = _hazardTab == tab;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final idleBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final idleBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);
    final idleText = isDark ? Colors.white : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _hazardTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.18) : idleBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? primary : idleBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primary : idleText,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeScrubber(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final isDark = theme.brightness == Brightness.dark;
        final slots = state is WeatherLoaded
            ? _buildFiveMinSlots(state.weatherData.hourly)
            : const <_FiveMinSlot>[];

        final selectedIndex = _clampIndex(_selectedSlotIndex, slots.length);
        final selectedTime =
            slots.isNotEmpty ? slots[selectedIndex].time : DateTime.now();
        final localSelectedTime = selectedTime.toLocal();
        final isNow =
            selectedTime.difference(DateTime.now()).abs().inMinutes <= 30;
        final barBg = isDark
            ? Colors.black.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.94);
        final barBorder = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08);

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomPadding + 16,
          ),
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              top: BorderSide(color: barBorder, width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 60),
                  Text(
                    isNow
                        ? 'Now · Local'
                        : '${DateTimeUtils.formatDate(localSelectedTime)} · Local',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    DateTimeUtils.formatTime(localSelectedTime),
                    style: TextStyle(
                      color: primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  InkResponse(
                    onTap: _openLayerSheet,
                    radius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.layers,
                        color: primary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (slots.length > 1)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: primary,
                    inactiveTrackColor: primary.withValues(alpha: 0.22),
                    thumbColor: primary,
                    overlayColor: primary.withValues(alpha: 0.18),
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
                    color: primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(height: 8),
              if (slots.isNotEmpty)
                _buildSlotTicks(context, slots, selectedIndex)
              else
                _buildTimeTicksSkeleton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeTicksSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final tickColor = theme.colorScheme.onSurface.withValues(alpha: 0.18);
    final labelColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
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
                    style: TextStyle(color: labelColor, fontSize: 10),
                  )
                else
                  const SizedBox(height: 12),
                const SizedBox(height: 2),
                Container(
                  width: 2,
                  height: 14,
                  decoration: BoxDecoration(
                    color: tickColor,
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

  Widget _buildSlotTicks(
    BuildContext context,
    List<_FiveMinSlot> slots,
    int selectedIndex,
  ) {
    final count = slots.length;
    if (count == 0) return _buildTimeTicksSkeleton(context);

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

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final labelColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final tickIdle = theme.colorScheme.onSurface.withValues(alpha: 0.3);

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
                            DateTimeUtils.formatTime(slots[i].time.toLocal()),
                            style: TextStyle(
                              color: labelColor,
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
                            color: i == selectedIndex ? primary : tickIdle,
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

enum _HazardTab { rain, landslide }

enum _Severity { advisory, caution, danger, emergency }

extension on _Severity {
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
}

class _HazardPoint {
  final LatLng location;
  final _Severity severity;
  const _HazardPoint(this.location, this.severity);
}

class _LandslidePolygonItem {
  final List<LatLng> ring;
  final _Severity severity;
  final String name;
  final String source;
  const _LandslidePolygonItem(this.ring, this.severity, this.name, this.source);
}

_Severity _severityFromString(String s) {
  switch (s) {
    case 'caution':
      return _Severity.caution;
    case 'danger':
      return _Severity.danger;
    case 'emergency':
      return _Severity.emergency;
    case 'advisory':
    default:
      return _Severity.advisory;
  }
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

class _WeatherPin extends StatelessWidget {
  final Color color;
  final String emoji;
  final String primary;
  final String secondary;

  const _WeatherPin({
    required this.color,
    required this.emoji,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pinBg = isDark
        ? const Color(0xFF0B0B0B).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.96);
    final pinSecondary = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: pinBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    primary,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    secondary,
                    style: TextStyle(
                      color: pinSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tail triangle pointing down to the location
        CustomPaint(
          size: const Size(8, 6),
          painter: _PinTailPainter(color),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.5);
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
