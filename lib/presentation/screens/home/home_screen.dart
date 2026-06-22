import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../../domain/entities/location.dart';
import '../../blocs/alerts/alert_bloc.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';
import '../../widgets/sos_alert_banner.dart';
import '../../widgets/stale_data_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()
        ..add(
          LoadWeather(
            location: const Location(
              id: 'island_wide',
              name: 'Sri Lanka',
              country: 'Sri Lanka',
              latitude: 7.8731,
              longitude: 80.7718,
            ),
          ),
        ),
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  bool _isIslandWide = true;
  final MapController _mapController = MapController();
  LatLng? _gpsLocation;

  static const _colombo = LatLng(6.9271, 79.8612);

  void _onToggleChanged(bool isNational) {
    setState(() => _isIslandWide = isNational);
    if (isNational) {
      _mapController.move(_colombo, SLMapConstants.initialZoom);
      context.read<WeatherBloc>().add(
        LoadWeather(
          location: const Location(
            id: 'island_wide',
            name: 'Sri Lanka',
            country: 'Sri Lanka',
            latitude: 7.8731,
            longitude: 80.7718,
          ),
        ),
      );
    } else {
      _mapController.move(_gpsLocation ?? _colombo, 12.0);
      context.read<WeatherBloc>().add(const LoadWeather(useGps: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WeatherBloc, WeatherState>(
      listener: (context, state) {
        if (!_isIslandWide &&
            state is WeatherLoaded &&
            state.location != null) {
          final loc = state.location!;
          final newLatLng = LatLng(loc.latitude, loc.longitude);
          if (_gpsLocation != newLatLng) {
            setState(() => _gpsLocation = newLatLng);
            _mapController.move(newLatLng, 12.0);
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Top toggle bar — Island-wide / Local + SOS fetch button
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: NationalLocalToggle(
                        isNational: _isIslandWide,
                        onChanged: _onToggleChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AlertBloc>().add(const RefreshAlerts());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1744),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.sos_outlined),
                      label: Text(
                        'SOS Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Map section
            Expanded(flex: 55, child: _buildMapSection(context)),
            // Weather & Alert section
            Expanded(flex: 45, child: _buildWeatherAlertSection(context)),
          ],
        ),
      ),
    );
  }

  // ── Map ──────────────────────────────────────────────────────────────

  Widget _buildMapSection(BuildContext context) {
    return Column(
      children: [
        // Rainbow gradient line
        Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF1744),
                Color(0xFFFF9100),
                Color(0xFFFFEA00),
                Color(0xFF00E676),
                Color(0xFF00B0FF),
                Color(0xFF651FFF),
                Color(0xFFFF4081),
              ],
            ),
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _isIslandWide
                  ? SLMapConstants.center
                  : (_gpsLocation ?? SLMapConstants.center),
              initialZoom: _isIslandWide ? SLMapConstants.initialZoom : 12.0,
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
              TileLayer(
                urlTemplate: ApiConstants.owmPrecipitationOverlay,
                userAgentPackageName: 'com.example.nerv_d_prevention',
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
              ),
              // Only show location marker in Local mode
              if (!_isIslandWide && _gpsLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _gpsLocation!,
                      child: _buildLocationMarker(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Weather + Alert Section ──────────────────────────────────────────

  Widget _buildWeatherAlertSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      color: theme.colorScheme.surface,
      child: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoading) {
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }

          if (state is WeatherError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.t('home.weatherUnavailable'),
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          if (state is WeatherLoaded) {
            return _buildLoadedContent(context, state);
          }

          // WeatherInitial — show placeholder
          return Center(
            child: Text(
              l10n.t('home.loadingWeather'),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, WeatherLoaded state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final data = state.weatherData;
    final current = data.current;
    final alerts = WeatherAlertDeriver.deriveAlerts(
      data,
      districtName: state.location?.name,
    );

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      onRefresh: () async {
        // Refresh both the local weather and the upstream SOS pipeline.
        context.read<WeatherBloc>().add(const RefreshWeather());
        context.read<AlertBloc>().add(const RefreshAlerts());
        await context.read<AlertBloc>().stream.firstWhere(
          (s) => s is AlertLoaded || s is AlertError,
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          // ── SOS / critical alerts from upstream ──
          BlocBuilder<AlertBloc, AlertState>(
            builder: (context, alertState) {
              if (alertState is AlertLoaded && alertState.alerts.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alertState.isStaleCache)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${l10n.t('home.sosStalePrefix')}${_formatRelativeTime(alertState.lastFetched)}',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ...alertState.alerts.map(
                      (a) => SosAlertBanner(
                        alert: a,
                        onTap: () {
                          // Future: navigate to an alert-detail screen.
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Stale data banner
          if (state.isStaleCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: StaleDataBanner(lastUpdated: data.lastUpdated),
            ),

          // Section header
          Text(
            _isIslandWide
                ? l10n.t('home.islandWide')
                : state.location?.name ?? l10n.t('home.local'),
            style: TextStyle(
              color: onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // ── Current conditions chip ──
          _buildCurrentConditionsChip(context, current, state.location?.name),
          const SizedBox(height: 16),

          // ── Derived alerts ──
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAlertInfoCard(
                context,
                title: alert.title,
                alertType: alert.alertType,
                severity: alert.severity,
                timestamp:
                    'As of ${alert.timestamp.year}/'
                    '${alert.timestamp.month.toString().padLeft(2, '0')}/'
                    '${alert.timestamp.day.toString().padLeft(2, '0')}  '
                    '${alert.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${alert.timestamp.minute.toString().padLeft(2, '0')}',
                description: alert.description,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Human-friendly relative time used for the "last updated" hint
  /// under stale SOS alerts.
  static String _formatRelativeTime(DateTime? then) {
    if (then == null) return 'never';
    final delta = DateTime.now().difference(then);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hr ago';
    return '${delta.inDays} d ago';
  }

  // ── Current Conditions Chip ──────────────────────────────────────────

  Widget _buildCurrentConditionsChip(
    BuildContext context,
    dynamic current,
    String? locationName,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final temp = current.temperature;
    final feelsLike = current.apparentTemperature;
    final humidity = current.humidity;
    final windSpeed = current.windSpeed;
    final weatherDesc = WeatherCodeMapping.getDescription(
      current.weatherCode,
      isDay: current.isDay,
    );
    final weatherEmoji = WeatherCodeMapping.getIcon(
      current.weatherCode,
      isDay: current.isDay,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerTheme.color ?? onSurface.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Temp + emoji
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weatherEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 8),
                  Text(
                    '${temp.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                weatherDesc,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.65),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Details column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _conditionDetail(
                context,
                'Feels like',
                '${feelsLike.toStringAsFixed(1)}°C',
              ),
              const SizedBox(height: 4),
              _conditionDetail(
                context,
                'Humidity',
                '${humidity.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 4),
              _conditionDetail(
                context,
                'Wind',
                '${windSpeed.toStringAsFixed(1)} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conditionDetail(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Alert Card ───────────────────────────────────────────────────────

  Widget _buildAlertInfoCard(
    BuildContext context, {
    required String title,
    required SLAlertType alertType,
    required SeverityLevel severity,
    required String timestamp,
    required String description,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final color = severity == SeverityLevel.calm
        ? severity.color
        : Color(int.parse(alertType.hexColor.replaceFirst('#', '0xFF')));

    return InkWell(
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert icon circle with severity color
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              _getAlertIcon(alertType),
              color: color.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        severity.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.chevron_right,
              color: onSurface.withValues(alpha: 0.35),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(SLAlertType type) {
    switch (type) {
      case SLAlertType.flood:
        return Icons.water;
      case SLAlertType.landslide:
        return Icons.terrain;
      case SLAlertType.cyclone:
        return Icons.cyclone;
      case SLAlertType.lightning:
        return Icons.bolt;
      case SLAlertType.coastalWarning:
        return Icons.beach_access;
      case SLAlertType.tsunami:
        return Icons.waves;
      case SLAlertType.earthquake:
        return Icons.public;
    }
  }

  // ── Location Marker ─────────────────────────────────────────────────

  Widget _buildLocationMarker() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer accuracy circle (pulsing ring visual)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.15),
            border: Border.all(
              color: primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
        ),
        // Inner filled dot
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            border: Border.all(
              color: theme.colorScheme.onPrimary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
