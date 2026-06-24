import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/alert.dart';
import '../../../core/constants/app_colors.dart';

/// Subscribes to the `alerts` table over Supabase Realtime and emits
/// new/updated [Alert]s to local listeners.
///
/// Enable Realtime for the table once via:
///   ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
/// (already done in 20260624_initial_schema.sql).
///
/// Realtime is opt-in per table. If you create new tables and want them
/// to fire change events, run the same `ALTER PUBLICATION` statement for
/// each.
class RealtimeAlertsService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _controller = StreamController<List<Alert>>.broadcast();

  /// Stream of all currently active alerts. New subscribers receive the
  /// initial snapshot immediately on `subscribe()`, then incremental
  /// updates as rows change.
  Stream<List<Alert>> get alerts => _controller.stream;

  RealtimeAlertsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Open the Realtime channel. Idempotent — calling twice is a no-op.
  Future<void> subscribe() async {
    if (_channel != null) return;

    final channel = _client
        .channel('public:alerts')
        // Postgres Changes listens to INSERT / UPDATE / DELETE on the table.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alerts',
          callback: _onChange,
        )
        .subscribe();

    _channel = channel;

    // Initial snapshot — fetch current rows so the UI doesn't wait for
    // the first change event before showing data.
    await _emitSnapshot();
  }

  /// Close the channel. Safe to call multiple times.
  Future<void> unsubscribe() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  Future<void> _emitSnapshot() async {
    try {
      final rows = await _client
          .from('alerts')
          .select()
          .order('issued_at', ascending: false)
          .limit(100);
      final list = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(_rowToAlert)
          .toList();
      _controller.add(list);
    } catch (e) {
      // Realtime is an enhancement — don't crash the app on failure.
      // The AlertBloc falls back to its own polling on cache miss.
    }
  }

  void _onChange(PostgresChangePayload payload) {
    // Any change triggers a snapshot refetch. Cheap because we cap at
    // 100 rows. For larger tables, switch to incremental upsert by id.
    _emitSnapshot();
  }

  /// Map a `alerts` table row to the in-app [Alert] entity. The
  /// severity column is stored as the enum *name* (lowercase).
  Alert _rowToAlert(Map<String, dynamic> row) {
    final severityName = (row['severity'] as String? ?? 'info').toLowerCase();
    final severity = SeverityLevel.values.firstWhere(
      (s) => s.name == severityName,
      orElse: () => SeverityLevel.info,
    );
    return Alert(
      id: row['id'] as String,
      type: row['type'] as String? ?? 'unknown',
      headline: row['headline'] as String? ?? '',
      description: row['description'] as String? ?? '',
      severity: severity,
      issuedTime: DateTime.parse(row['issued_at'] as String).toLocal(),
      expiryTime: row['expiry_at'] == null
          ? null
          : DateTime.parse(row['expiry_at'] as String).toLocal(),
      location: row['location'] as String? ?? '',
      metadata: row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'] as Map)
          : null,
    );
  }

  Future<void> dispose() async {
    await unsubscribe();
    await _controller.close();
  }
}