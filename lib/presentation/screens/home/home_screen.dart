import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';
import '../../widgets/stale_data_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(const LoadWeather()),
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
  SLDistrict? _selectedDistrict;
  final MapController _mapController = MapController();

  void _updateDistrict(bool isNational, SLDistrict? district) {
    setState(() {
      _isIslandWide = isNational;
      _selectedDistrict = district;
    });
    // Animate map to new location
    _mapController.move(
      _mapCenterFor(isNational, district),
      _mapZoomFor(isNational, district),
    );
    if (district != null) {
      context.read<WeatherBloc>().add(
        LoadWeatherForDistrict(district: district),
      );
    } else {
      context.read<WeatherBloc>().add(const LoadWeather());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top toggle bar — Island-wide / District
          SafeArea(
            bottom: false,
            child: NationalLocalToggle(
              isNational: _isIslandWide,
              selectedDistrict: _selectedDistrict,
              onChanged: (isNational) {
                _updateDistrict(isNational, null);
              },
              onDistrictSelected: (district) {
                _updateDistrict(false, district);
              },
            ),
          ),
          // Support banner
          _buildSupporterBanner(context),
          // Map section
          Expanded(flex: 55, child: _buildMapSection(context)),
          // Weather & Alert section
          Expanded(flex: 45, child: _buildWeatherAlertSection(context)),
        ],
      ),
    );
  }

  // ── Supporter Banner ─────────────────────────────────────────────────

  Widget _buildSupporterBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Join as a Supporter',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              Text(
                'Learn More',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Map ──────────────────────────────────────────────────────────────

  LatLng _mapCenterFor(bool isNational, SLDistrict? district) {
    if (!isNational && district != null) {
      return district.center;
    }
    return SLMapConstants.center;
  }

  double _mapZoomFor(bool isNational, SLDistrict? district) {
    if (!isNational && district != null) {
      return 10.0;
    }
    return SLMapConstants.initialZoom;
  }

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
              initialCenter: _mapCenterFor(_isIslandWide, _selectedDistrict),
              initialZoom: _mapZoomFor(_isIslandWide, _selectedDistrict),
              minZoom: SLMapConstants.minZoom,
              maxZoom: SLMapConstants.maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.nerv_d_prevention',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _mapCenterFor(_isIslandWide, _selectedDistrict),
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
    return Container(
      color: Colors.black,
      child: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            );
          }

          if (state is WeatherError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Weather data unavailable',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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
              'Loading weather...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, WeatherLoaded state) {
    final data = state.weatherData;
    final current = data.current;
    final alerts = WeatherAlertDeriver.deriveAlerts(
      data,
      districtName: state.selectedDistrict?.displayName,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
        // Stale data banner
        if (state.isStaleCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: StaleDataBanner(lastUpdated: data.lastUpdated),
          ),

        // Section header
        Text(
          _isIslandWide
              ? 'Island-wide'
              : _selectedDistrict?.displayName ?? 'District',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        // ── Current conditions chip ──
        _buildCurrentConditionsChip(current, state.location?.name),
        const SizedBox(height: 16),

        // ── Derived alerts ──
        ...alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAlertInfoCard(
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
    );
  }

  // ── Current Conditions Chip ──────────────────────────────────────────

  Widget _buildCurrentConditionsChip(dynamic current, String? locationName) {
    final temp = current.temperature;
    final feelsLike = current.apparentTemperature;
    final humidity = current.humidity;
    final windSpeed = current.windSpeed;
    final weatherDesc = WeatherCodeMapping.getDescription(current.weatherCode);
    final weatherEmoji = WeatherCodeMapping.getIcon(current.weatherCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.6),
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
                'Feels like',
                '${feelsLike.toStringAsFixed(1)}°C',
              ),
              const SizedBox(height: 4),
              _conditionDetail('Humidity', '${humidity.toStringAsFixed(0)}%'),
              const SizedBox(height: 4),
              _conditionDetail('Wind', '${windSpeed.toStringAsFixed(1)} km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conditionDetail(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Alert Card ───────────────────────────────────────────────────────

  Widget _buildAlertInfoCard({
    required String title,
    required SLAlertType alertType,
    required SeverityLevel severity,
    required String timestamp,
    required String description,
  }) {
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
              color: color.withValues(alpha: 0.85),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
              color: Colors.white.withValues(alpha: 0.3),
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
    }
  }

  // ── Location Marker ─────────────────────────────────────────────────

  Widget _buildLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer accuracy circle (pulsing ring visual)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.35),
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
            color: const Color(0xFF00BCD4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.5),
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
