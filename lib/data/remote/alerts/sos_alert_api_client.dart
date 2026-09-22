import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/alert.dart';

/// Client for the app's disaster-alert feed.
///
/// Alerts are aggregated server-side by the `alert-aggregator` Edge Function
/// (Open-Meteo thresholds + GDACS cyclone/tsunami RSS, using the API keys
/// stored in Supabase Secrets) and persisted into the `public.alerts` table.
/// This client reads that table — it is the single source of truth for all
/// screens (Home, Timeline). The old direct-to-GDACS GeoJSON call was retired
/// because `gdacs.org/gdacsapi/api/events/geojson` now returns 404.
///
/// `public.alerts` has an open SELECT RLS policy, so the anon key can read it
/// without a signed-in session.
class SosAlertApiClient {
  final SupabaseClient _client;

  SosAlertApiClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Returns currently-active alerts (most severe first is handled by the
  /// bloc). Empty list on any error — the repository falls back to cache /
  /// offline demo so the UI never blocks on an upstream outage.
  Future<List<Alert>> fetchSriLankaAlerts() async {
    try {
      final rows = await _client
          .from('alerts')
          .select()
          .order('issued_at', ascending: false)
          .limit(100);

      final now = DateTime.now().toUtc();
      final alerts = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(_rowToAlert)
          .whereType<Alert>()
          // Drop rows whose expiry has already passed.
          .where((a) => a.expiryTime == null || a.expiryTime!.isAfter(now))
          .toList();
      return alerts;
    } catch (_) {
      return const [];
    }
  }

  /// Map an `alerts` row to the in-app [Alert] entity. The severity column
  /// stores the enum *name* in lowercase (critical / emergency / warning /
  /// advisory / info / calm).
  Alert? _rowToAlert(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return null;

    final severityName = (row['severity'] as String? ?? 'info').toLowerCase();
    final severity = SeverityLevel.values.firstWhere(
      (s) => s.name == severityName,
      orElse: () => SeverityLevel.info,
    );

    final issuedRaw = row['issued_at'] as String?;
    final expiryRaw = row['expiry_at'] as String?;

    return Alert(
      id: id,
      type: row['type'] as String? ?? 'unknown',
      headline: row['headline'] as String? ?? '',
      description: row['description'] as String? ?? '',
      severity: severity,
      issuedTime: issuedRaw != null
          ? DateTime.parse(issuedRaw).toLocal()
          : DateTime.now().toLocal(),
      expiryTime: expiryRaw == null ? null : DateTime.parse(expiryRaw).toLocal(),
      location: row['location'] as String? ?? '',
      metadata: row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'] as Map)
          : null,
    );
  }
}
