import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/alert.dart';

/// Client for the app's disaster-alert feed.
///
/// Alerts are aggregated server-side by the `alert-aggregator` Edge Function
/// (Open-Meteo thresholds + GDACS cyclone/tsunami RSS, using the API keys
/// stored in Supabase Secrets) and persisted to Supabase Storage as the
/// `alerts.json` object in the `table-exports` bucket (the old `public.alerts`
/// table was removed). This client reads that object — it is the single source
/// of truth for all screens (Home, Timeline). The old direct-to-GDACS GeoJSON
/// call was retired because `gdacs.org/gdacsapi/api/events/geojson` returns 404.
///
/// The `table-exports` bucket has an open object SELECT policy, so the anon key
/// can download `alerts.json` without a signed-in session.
class SosAlertApiClient {
  final SupabaseClient _client;

  SosAlertApiClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Supabase Storage location written by the `alert-aggregator` function.
  static const String _bucket = 'table-exports';
  static const String _alertsObject = 'alerts.json';

  /// Returns currently-active alerts (most severe first). Throws on any
  /// transport/parse failure so the repository can tell "no alerts" (a valid
  /// empty feed) apart from "fetch failed" and keep serving the cache.
  Future<List<Alert>> fetchSriLankaAlerts() async {
    final bytes = await _client.storage.from(_bucket).download(_alertsObject);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List) {
      throw const FormatException('alerts.json is not a JSON array');
    }

    final now = DateTime.now().toUtc();
    final alerts = <Alert>[];
    for (final row in decoded) {
      final alert = _rowToAlert(row as Map<String, dynamic>);
      if (alert == null) continue;
      // Drop rows whose expiry has already passed.
      if (alert.expiryTime != null && !alert.expiryTime!.isAfter(now)) {
        continue;
      }
      alerts.add(alert);
    }
    // Rank by severity first, then recency, so the 100-row cap keeps the
    // most important alerts rather than simply the 100 most recent — an
    // older Critical must never be truncated in favour of newer Info rows.
    alerts.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      if (bySeverity != 0) return bySeverity;
      return b.issuedTime.compareTo(a.issuedTime);
    });
    return alerts.take(100).toList();
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
