import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/alert.dart';
import '../../../domain/repositories/alert_repository.dart';
import '../local/hive/hive_service.dart';
import '../remote/alerts/sos_alert_api_client.dart';

/// Caches the upstream response in a dedicated Hive box so the app
/// stays useful offline. Cache TTL is [currentWeatherCacheTtl] (10 min) —
/// short enough that a user who reopens the app after a storm will see
/// fresh data when online, but long enough to absorb brief outages.
class AlertRepositoryImpl implements AlertRepository {
  final SosAlertApiClient _apiClient;
  final HiveService _hiveService;

  /// In-memory copy of the last list. Sourced from cache on init and
  /// refreshed on each successful fetch so the UI never blocks on disk.
  List<Alert> _alerts = const [];
  DateTime? _lastFetched;

  AlertRepositoryImpl({
    required SosAlertApiClient apiClient,
    required HiveService hiveService,
  }) : _apiClient = apiClient,
       _hiveService = hiveService {
    _alerts = _hiveService.getCachedSosAlerts() ?? const [];
    _lastFetched = _hiveService.getSosAlertsCacheTimestamp();
  }

  @override
  DateTime? get lastFetched => _lastFetched;

  @override
  bool get hasFreshCache {
    final ts = _lastFetched;
    if (ts == null) return false;
    return DateTime.now().difference(ts) < ApiConstants.currentWeatherCacheTtl;
  }

  @override
  Future<List<Alert>> getActiveAlerts() async {
    if (hasFreshCache) return _alerts;
    await refresh();
    return _alerts;
  }

  @override
  Future<void> refresh() async {
    try {
      final fresh = await _apiClient.fetchSriLankaAlerts();
      // The client now throws on transport/parse failure, so reaching here
      // with an empty list means the feed is genuinely empty (all alerts
      // lifted / calm). Clear the cache instead of pinning a stale list.
      final sorted = _sortBySeverity(fresh);
      _alerts = sorted;
      _lastFetched = DateTime.now();
      await _hiveService.cacheSosAlerts(sorted);
    } catch (_) {
      // Network / parse failure — serve cached if we have any.
      // If this is the first app run and there is no cache yet, generate
      // an in-memory offline fallback so SOS UI still works.
      if (_alerts.isEmpty) {
        final fallback = _generateOfflineFallback();
        _alerts = _sortBySeverity(fallback);
        _lastFetched = DateTime.now();
        // Intentionally NOT persisted to Hive: the demo alert must never be
        // mistaken for a real feed on the next launch.
      }
    }
  }

  List<Alert> _generateOfflineFallback() {
    final now = DateTime.now();

    // These are generic, user-facing examples meant to keep the SOS
    // feature functional offline. Severity ordering will be handled by
    // _sortBySeverity().
    return [
      Alert(
        id: 'offline_demo_1',
        type: 'sos_offline_demo',
        headline: 'Offline SOS Alert',
        description:
            'SOS alerts are currently unavailable due to no network. This offline demo alert keeps the feature working.',
        severity: SeverityLevel.info,
        issuedTime: now.subtract(const Duration(hours: 1)),
        expiryTime: now.add(const Duration(hours: 5)),
        location: 'Sri Lanka',
        metadata: const {'offline': true},
      ),
    ];
  }

  /// The Supabase `alerts` table is the only source, so we re-sort by
  /// [SeverityLevel] (most severe first) so the UI can render without
  /// further processing.
  static List<Alert> _sortBySeverity(List<Alert> alerts) {
    final copy = [...alerts];
    copy.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return copy;
  }
}
