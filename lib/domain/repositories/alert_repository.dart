import '../../../domain/entities/alert.dart';

/// Abstraction over the SOS / disaster-alert data pipeline.
///
/// Implementations are responsible for fetching alerts from an upstream
/// source (currently GDACS) and persisting them locally so the app
/// remains functional offline. The UI consumes only this interface.
abstract class AlertRepository {
  /// Returns the current set of active alerts, sorted by severity
  /// (most severe first). May return cached data if the upstream call
  /// fails; the caller can inspect [SosAlertLoaded.lastFetched] to
  /// decide whether to display a "stale" badge.
  Future<List<Alert>> getActiveAlerts();

  /// The timestamp of the last successful upstream fetch, or `null` if
  /// no fetch has succeeded yet.
  DateTime? get lastFetched;

  /// Force a refresh from the upstream. The UI calls this on pull-to-
  /// refresh and on a configurable polling interval.
  Future<void> refresh();

  /// True if the local cache is recent enough to skip a network round-
  /// trip. The threshold is owned by the implementation (10 minutes).
  bool get hasFreshCache;
}
