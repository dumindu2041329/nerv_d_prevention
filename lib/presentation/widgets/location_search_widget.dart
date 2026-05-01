import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_spacing.dart';
import '../../domain/entities/location.dart';
import '../blocs/weather/weather_bloc.dart';

class LocationSearchWidget extends StatelessWidget {
  final Function(Location) onLocationSelected;

  const LocationSearchWidget({
    super.key,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    // We capture the bloc to pass it to the modal bottom sheet
    final weatherBloc = context.read<WeatherBloc>();
    
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => showSearchSheet(context, weatherBloc, onLocationSelected),
    );
  }

  static void showSearchSheet(BuildContext context, WeatherBloc weatherBloc, Function(Location) onLocationSelected) {
    // Clear any previous search results before opening
    weatherBloc.add(const SearchLocations(query: ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: weatherBloc,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: _LocationSearchSheet(
                onLocationSelected: (location) {
                  Navigator.pop(context);
                  onLocationSelected(location);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const _LocationSearchSheet({
    required this.onLocationSelected,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<WeatherBloc>().add(SearchLocations(query: query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.space2),
        // Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search city or region...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(
                  color: theme.dividerTheme.color ?? Colors.grey,
                ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // GPS Option
        ListTile(
          leading: Icon(
            Icons.my_location,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'Use current location',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          onTap: () {
            // Null location falls back to GPS in WeatherBloc
            widget.onLocationSelected(
              const Location(
                id: 'gps',
                name: 'Current Location',
                latitude: 0,
                longitude: 0,
                isGps: true,
              ),
            );
          },
        ),
        const Divider(),
        // Results list
        Expanded(
          child: BlocBuilder<WeatherBloc, WeatherState>(
            builder: (context, state) {
              if (state is WeatherLoaded) {
                if (state.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_searchController.text.length >= 2 && state.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        Text(
                          'No locations found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final location = state.searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(location.name),
                      subtitle: Text(location.displayName),
                      onTap: () => widget.onLocationSelected(location),
                    );
                  },
                );
              }
              // If not WeatherLoaded, maybe WeatherLoading, etc.
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}