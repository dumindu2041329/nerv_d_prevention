import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/di/injection.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';

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
  bool _isNational = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top toggle bar
          SafeArea(
            bottom: false,
            child: NationalLocalToggle(
              isNational: _isNational,
              onChanged: (val) => setState(() => _isNational = val),
            ),
          ),
          // Join as supporter banner
          _buildSupporterBanner(context),
          // Map section (takes ~55% of remaining space)
          Expanded(
            flex: 55,
            child: _buildMapSection(context),
          ),
          // Alert info section (takes ~45% of remaining space)
          Expanded(
            flex: 45,
            child: _buildAlertSection(context),
          ),
        ],
      ),
    );
  }

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

  Widget _buildMapSection(BuildContext context) {
    // Rainbow gradient line at top
    return Column(
      children: [
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
            options: MapOptions(
              initialCenter: const LatLng(36.0, 138.0),
              initialZoom: 5,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.nerv_d_prevention',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection(BuildContext context) {
    return Container(
      color: Colors.black,
      child: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            children: [
              // "National" section header
              Text(
                _isNational ? 'National' : 'Local',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              // Latest earthquake / alert info card
              _buildAlertInfoCard(
                icon: Icons.public,
                title: 'Off. Ibaraki (Int. 1)',
                timestamp: 'As of ${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}  ${DateTime.now().hour.toString().padLeft(2, '0')}:00',
                description: 'At around 2:27am, an earthquake with a magnitude of 2.9 occurred in Off. Ibaraki at a depth of 50km. The maximum intensity wa...',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertInfoCard({
    required IconData icon,
    required String title,
    required String timestamp,
    required String description,
  }) {
    return InkWell(
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earthquake icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
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
}
