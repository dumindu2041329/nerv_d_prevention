import '../../../core/constants/app_constants.dart';
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
  })  : _apiClient = apiClient,
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
      if (fresh.isEmpty && _alerts.isNotEmpty) {
        // Upstream returned nothing (likely a temporary outage). Keep
        // serving the cached list and do NOT clobber it.
        return;
      }
      final sorted = _sortBySeverity(fresh);
      _alerts = sorted;
      _lastFetched = DateTime.now();
      await _hiveService.cacheSosAlerts(sorted);
    } catch (_) {
      // Network / parse failure — serve cached if we have any.
    }
  }

  /// GDACS is the only source, so it returns its events in a stable
  /// order. We re-sort by [SeverityLevel] (most severe first) so the
  /// UI can render without further processing.
  static List<Alert> _sortBySeverity(List<Alert> alerts) {
    final copy = [...alerts];
    copy.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return copy;
  }
}
