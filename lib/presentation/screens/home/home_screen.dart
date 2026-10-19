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
import '../../widgets/alert_banner.dart';
import '../../widgets/stale_data_banner.dart';
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/posture_gauge.dart';
import '../../widgets/nerv/island_mark.dart';
import '../../widgets/nerv/deck_header.dart';

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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  LatLng? _gpsLocation;

  void _onToggleChanged(bool isNational) {
    setState(() => _isIslandWide = isNational);
    if (isNational) {
      _mapController.move(SLMapConstants.center, SLMapConstants.initialZoom);
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
      _mapController.move(_gpsLocation ?? SLMapConstants.center, 12.0);
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
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  _buildTopOverlay(context),
                  Expanded(child: _buildMapSection(context)),
                ],
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.25,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.25, 0.45, 0.85],
              controller: _sheetController,
              builder: _buildWeatherAlertSheet,
            ),
          ],
        ),
      ),
    );
  }

  // ── Top overlay: posture header + mode switch ─────────────────────

  Widget _buildTopOverlay(BuildContext context) {
    final nerv = context.nerv;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.96),
            Colors.black.withValues(alpha: 0.82),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IslandMark(
                    size: 18,
                    color: nerv.onSurface.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Eyebrow(
                      'SRI LANKA · ${nerv.monsoon.name.toUpperCase()}',
                      color: nerv.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const LiveClock(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: NationalLocalToggle(
                    isNational: _isIslandWide,
                    onChanged: _onToggleChanged,
                  ),
                ),
                const SizedBox(width: 12),
                _buildSosButton(context),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Posture state line — reactive to current alert severity.
          BlocBuilder<WeatherBloc, WeatherState>(
            builder: (context, state) {
              final posture = _postureFromWeather(state);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                height: 2,
                color: posture.color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSosButton(BuildContext context) {
    final critical = SeverityLevel.critical.color;

    return GestureDetector(
      onTap: () {
        context.read<AlertBloc>().add(const RefreshAlerts());
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: critical.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: critical.withValues(alpha: 0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sos_outlined, size: 16, color: critical),
            const SizedBox(width: 6),
            Text(
              'SOS',
              style: TextStyle(
                color: critical,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map ──────────────────────────────────────────────────────────────

  Widget _buildMapSection(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _isIslandWide
            ? SLMapConstants.center
            : (_gpsLocation ?? SLMapConstants.center),
        initialZoom: _isIslandWide ? SLMapConstants.initialZoom : 12.0,
        minZoom: SLMapConstants.minZoom,
        maxZoom: SLMapConstants.maxZoom,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            SLMapConstants.viewSouthWest,
            SLMapConstants.viewNorthEast,
          ),
        ),
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
    );
  }

  // ── Operations readout sheet ────────────────────────────────────────

  Widget _buildWeatherAlertSheet(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2,
              ),
            );
          }

          if (state is WeatherError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.signal_wifi_off,
                      size: 28,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.t('home.weatherUnavailable'),
                      style: context.nerv.body,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is WeatherLoaded) {
            return _buildLoadedContent(context, scrollController, state);
          }

          return Center(
            child: Text(
              l10n.t('home.loadingWeather'),
              style: context.nerv.dataLabel,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    ScrollController scrollController,
    WeatherLoaded state,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final nerv = context.nerv;
    final data = state.weatherData;
    final current = data.current;
    final alerts = WeatherAlertDeriver.deriveAlerts(
      data,
      districtName: state.location?.name,
    );
    final posture = _postureFromWeather(state);

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      onRefresh: () async {
        context.read<WeatherBloc>().add(const RefreshWeather());
        final alertBloc = context.read<AlertBloc>();
        alertBloc.add(const RefreshAlerts());
        // Bounded wait: never leave the spinner up forever if the alert
        // stream doesn't emit a terminal state (network stall).
        await alertBloc.stream
            .firstWhere((s) => s is AlertLoaded || s is AlertError)
            .timeout(const Duration(seconds: 15), onTimeout: () => alertBloc.state);
      },
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Current posture ──
          Row(
            children: [
              Expanded(
                child: Eyebrow('CURRENT POSTURE'),
              ),
              Text(
                state.location?.name ?? l10n.t('home.islandWide'),
                style: nerv.dataLabel.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                WeatherCodeMapping.getIcon(
                  current.weatherCode,
                  isDay: current.isDay,
                ),
                style: const TextStyle(fontSize: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${current.temperature.toStringAsFixed(1)}°C',
                      style: nerv.numeral(size: 52),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      WeatherCodeMapping.getDescription(
                        current.weatherCode,
                        isDay: current.isDay,
                      ),
                      style: nerv.body.copyWith(
                        color: onSurface.withValues(alpha: 0.65),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Signature: the posture gauge ──
          PostureGauge(level: posture),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── SOS / critical alerts from upstream ──
          BlocBuilder<AlertBloc, AlertState>(
            builder: (context, alertState) {
              if (alertState is AlertLoaded && alertState.alerts.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alertState.isStaleCache)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${l10n.t('home.sosStalePrefix')}${_formatRelativeTime(alertState.lastFetched)}',
                          style: nerv.dataLabel.copyWith(
                            color: onSurface.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ...alertBannerWidgets(alertState.alerts),
                    const SizedBox(height: 12),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ── Stale data banner ──
          if (state.isStaleCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaleDataBanner(lastUpdated: data.lastUpdated),
            ),

          // ── Conditions band ──
          Eyebrow('CONDITIONS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DataTile(
                  label: 'FEELS LIKE',
                  value: '${current.apparentTemperature.toStringAsFixed(1)}°C',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DataTile(
                  label: 'HUMIDITY',
                  value: '${current.humidity.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DataTile(
                  label: 'WIND',
                  value: '${current.windSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Derived alert feed ──
          Row(
            children: [
              Expanded(child: Eyebrow('ALERT FEED')),
              Text(
                alerts.length.toString(),
                style: nerv.numeralSmall(size: 12).copyWith(
                  color: posture.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAlertLedgerRow(context, alert),
            ),
          ),
        ],
      ),
    );
  }

  // ── Posture helpers ──────────────────────────────────────────────────

  SeverityLevel _postureFromWeather(WeatherState? state) {
    if (state is! WeatherLoaded) return SeverityLevel.calm;
    final alerts = WeatherAlertDeriver.deriveAlerts(
      state.weatherData,
      districtName: state.location?.name,
    );
    return NervStyles.postureOf(alerts.map((a) => a.severity).toList());
  }

  /// Human-friendly relative time for stale SOS hints.
  static String _formatRelativeTime(DateTime? then) {
    if (then == null) return 'never';
    final delta = DateTime.now().difference(then);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hr ago';
    return '${delta.inDays} d ago';
  }

  // ── Alert ledger row ─────────────────────────────────────────────────

  Widget _buildAlertLedgerRow(BuildContext context, AlertItem alert) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final color = alert.severity == SeverityLevel.calm
        ? alert.severity.color
        : Color(int.parse(alert.alertType.hexColor.replaceFirst('#', '0xFF')));

    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: nerv.border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            alert.severity.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'As of ${alert.timestamp.year}/'
                        '${alert.timestamp.month.toString().padLeft(2, '0')}/'
                        '${alert.timestamp.day.toString().padLeft(2, '0')} · '
                        '${NervStyles.formatClockShort(alert.timestamp)}',
                        style: nerv.dataLabel.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alert.description,
                        style: nerv.body.copyWith(fontSize: 12.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.chevron_right,
                  color: onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Location marker ─────────────────────────────────────────────────

  Widget _buildLocationMarker() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
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
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
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

/// A single labelled data readout (console tile).
class _DataTile extends StatelessWidget {
  final String label;
  final String value;

  const _DataTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final nerv = context.nerv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label, color: nerv.onSurface.withValues(alpha: 0.45)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: nerv.numeralSmall(size: 14)),
          ),
        ],
      ),
    );
  }
}
