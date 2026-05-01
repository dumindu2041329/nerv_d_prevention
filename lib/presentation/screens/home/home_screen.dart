import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/alert.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/widgets.dart';

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

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WeatherError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'Failed to load information',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Please check your connection and try again',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    FilledButton.tonal(
                      onPressed: () {
                        context.read<WeatherBloc>().add(const LoadWeather());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is WeatherLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WeatherBloc>().add(const RefreshWeather());
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context, state),
                    ),
                    SliverToBoxAdapter(
                      child: _buildStatusBanner(context),
                    ),
                    SliverToBoxAdapter(
                      child: _buildAlertsSection(context),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCurrentWeather(context, state),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(context),
                    ),
                    SliverToBoxAdapter(
                      child: _buildForecastSection(context, state),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.space8),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WeatherLoaded state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space5,
        AppSpacing.space4,
        AppSpacing.space5,
        AppSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SeverityLevel.calm.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    'NERV',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                state.location?.displayName ?? 'Current Location',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Row(
            children: [
              LocationSearchWidget(
                onLocationSelected: (location) {
                  context.read<WeatherBloc>().add(SelectLocation(location: location));
                },
              ),
              const SizedBox(width: AppSpacing.space2),
              _buildHeaderIconButton(
                context,
                icon: Icons.notifications_outlined,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.space2),
              _buildHeaderIconButton(
                context,
                icon: Icons.settings_outlined,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: SeverityLevel.calm.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: SeverityLevel.calm.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: SeverityLevel.calm.color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Clear',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SeverityLevel.calm.color,
                  ),
                ),
                Text(
                  'No active alerts or warnings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    final demoAlerts = <Alert>[];

    if (demoAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Alerts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ...demoAlerts.map((alert) => AlertBanner(alert: alert)),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(BuildContext context, WeatherLoaded state) {
    final theme = Theme.of(context);
    final weather = state.weatherData.current;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.space5),
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    state.location?.displayName ?? 'Current Location',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${weather.temperature.round()}°',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 72,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              _buildWeatherDetail(
                context,
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${weather.humidity}%',
              ),
              const SizedBox(width: AppSpacing.space6),
              _buildWeatherDetail(
                context,
                icon: Icons.air,
                label: 'Wind',
                value: '${weather.windSpeed.round()} m/s',
              ),
              const SizedBox(width: AppSpacing.space6),
              _buildWeatherDetail(
                context,
                icon: Icons.visibility_outlined,
                label: 'Visibility',
                value: '${weather.cloudCover.round()} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: AppSpacing.space2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Radar & Layers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.radar,
                  title: 'Rain Radar',
                  subtitle: 'Precipitation',
                  color: Colors.blue,
                  onTap: () => context.go('/map'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.public,
                  title: 'Typhoon',
                  subtitle: 'Tropical Cyclone',
                  color: Colors.cyan,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.tsunami,
                  title: 'Tsunami/Wave',
                  subtitle: 'Ocean Warning',
                  color: Colors.teal,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.landscape,
                  title: 'Volcano',
                  subtitle: 'Eruption Alert',
                  color: Colors.deepOrange,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context, WeatherLoaded state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ForecastCard(dailyForecast: state.weatherData.daily),
        ],
      ),
    );
  }
}
