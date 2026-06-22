import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../domain/entities/timeline_event.dart';

/// Detailed view for a single [TimelineEvent]. Modeled after the
/// "Earthquake Info" style event report — a small map preview, the
/// headline stats (intensity / magnitude), and the event metadata.
///
/// All displayed values come from [TimelineEvent] fields populated by
/// [WeatherAlertDeriver] from the underlying WeatherAPI.com data, so
/// there are no hardcoded mock numbers on this screen.
class TimelineEventDetailScreen extends StatelessWidget {
  final TimelineEvent event;

  const TimelineEventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = event.severity.color;
    final report = _buildReport(event);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, color),
              _buildMapPreview(context, color),
              _buildReportHeader(context, report),
              _buildHighlightBox(context, report),
              _buildMetadataRows(context, report),
              Divider(
                height: 32,
                thickness: 0.5,
                indent: 20,
                endIndent: 20,
                color: onSurface.withValues(alpha: 0.18),
              ),
              _buildStatusMessage(context, report),
              const SizedBox(height: 24),
              _buildIntensityChips(context, report),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.chevron_left,
              color: onSurface,
              size: 28,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _titleFor(event.type),
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // balances the leading IconButton
        ],
      ),
    );
  }

  // ── Map Preview ─────────────────────────────────────────────────────

  Widget _buildMapPreview(BuildContext context, Color color) {
    // Use the event's real coordinates when available, otherwise fall
    // back to the Sri Lanka map center.
    final LatLng point = (event.latitude != null && event.longitude != null)
        ? LatLng(event.latitude!, event.longitude!)
        : SLMapConstants.center;

    final fadeColor = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: event.latitude != null ? 9.0 : 6.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: ApiConstants.mapTileHybrid,
                  userAgentPackageName: 'com.example.nerv_d_prevention',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      child: _EventPin(
                        color: color,
                        label: '${event.maxIntensity ?? '?'}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Soft bottom fade to blend with the page background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      fadeColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Report Header ───────────────────────────────────────────────────

  Widget _buildReportHeader(BuildContext context, _EventReport report) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Area Report',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'As of ${_formatReportDateTime(event.time)}',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusBadge(label: report.statusBadge, color: report.statusColor),
        ],
      ),
    );
  }

  // ── Highlight Box (Max Intensity + Magnitude) ───────────────────────

  Widget _buildHighlightBox(BuildContext context, _EventReport report) {
    final highlightBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8FB8E0)
        : const Color(0xFFB3CDF0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: highlightBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Max.\nIntensity',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.maxIntensity,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.magnitudeLabel,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.magnitude,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metadata rows ───────────────────────────────────────────────────

  Widget _buildMetadataRows(BuildContext context, _EventReport report) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final rows = <_MetaRow>[
      _MetaRow('Date/Time', report.dateTime),
      _MetaRow('Epicenter', report.epicenter),
      _MetaRow('Depth', report.depth),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _MetaRowTile(row: rows[i]),
            if (i < rows.length - 1)
              Divider(
                height: 24,
                thickness: 0.4,
                color: onSurface.withValues(alpha: 0.15),
              ),
          ],
        ],
      ),
    );
  }

  // ── Status message ──────────────────────────────────────────────────

  Widget _buildStatusMessage(BuildContext context, _EventReport report) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        report.statusMessage,
        style: TextStyle(
          color: onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Intensity chips ─────────────────────────────────────────────────

  Widget _buildIntensityChips(BuildContext context, _EventReport report) {
    if (report.intensityEntries.isEmpty) return const SizedBox.shrink();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final chipBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8FB8E0)
        : const Color(0xFFB3CDF0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in report.intensityEntries) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.badge,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.place,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Report derivation ───────────────────────────────────────────────

  _EventReport _buildReport(TimelineEvent event) {
    final alertType = SLAlertType.fromString(event.type);
    final isEarthquake = alertType == SLAlertType.earthquake;
    final isTsunami = alertType == SLAlertType.tsunami;

    // Status badge — tsunami context is only shown for earthquake /
    // tsunami events. Every other event uses a generic status label
    // driven by severity, so we never see "No Tsunami" on a flood,
    // cyclone, or any non-seismic report.
    final String statusBadge;
    final Color statusColor;
    if (event.isLifted) {
      statusBadge = 'Lifted';
      statusColor = const Color(0xFF616161);
    } else if (isEarthquake || isTsunami) {
      statusBadge = event.tsunamiFlag ? 'Tsunami Watch' : 'No Tsunami';
      statusColor = event.tsunamiFlag
          ? const Color(0xFFFF1744)
          : const Color(0xFF2E7D32);
    } else {
      statusBadge = _genericStatusFor(event.severity);
      statusColor = event.severity.color;
    }

    // Status sentence: prefer the event's own description, then a
    // type-appropriate fallback. Never make up data.
    final statusMessage = event.description ??
        (event.isLifted
            ? 'The advisory has been lifted. Conditions have returned to normal.'
            : 'Monitoring ongoing. Follow official DMC instructions and stay alert.');

    // Intensity entry — one chip per location the event applies to.
    // We currently have only the district center, so a single entry.
    final intensityEntries = <_IntensityEntry>[
      _IntensityEntry(
        badge: 'Int. ${event.maxIntensity ?? "?"}',
        place: '[${event.location ?? "Sri Lanka"}]',
      ),
    ];

    return _EventReport(
      maxIntensity: '${event.maxIntensity ?? "—"}',
      magnitude: _formatMagnitude(event.magnitude),
      magnitudeLabel: event.magnitudeLabel ?? 'Magnitude',
      dateTime: _formatReportDateTime(event.time),
      epicenter: event.location ?? 'Sri Lanka',
      depth: event.depthLabel ?? '—',
      statusBadge: statusBadge,
      statusColor: statusColor,
      statusMessage: statusMessage,
      intensityEntries: intensityEntries,
    );
  }

  /// Generic, severity-driven status label used for non-seismic
  /// events so the badge never shows tsunami-related text on a flood
  /// or cyclone report.
  String _genericStatusFor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return 'Critical';
      case SeverityLevel.emergency:
        return 'Emergency';
      case SeverityLevel.warning:
        return 'Warning';
      case SeverityLevel.advisory:
        return 'Advisory';
      case SeverityLevel.info:
        return 'Info';
      case SeverityLevel.calm:
        return 'All Clear';
    }
  }

  String _formatMagnitude(double? m) {
    if (m == null) return '—';
    if (m == 0) return '0';
    return m.toStringAsFixed(m < 10 ? 1 : 0);
  }

  String _formatReportDateTime(DateTime t) {
    // Match the "06/15 5:35pm" style used in the design reference.
    return '${DateFormat('M/d').format(t)} ${DateFormat('h:mm a').format(t).toLowerCase()}';
  }

  String _titleFor(String type) {
    final alertType = SLAlertType.fromString(type);
    if (alertType != null) return alertType.fullLabel;
    switch (type) {
      case 'earthquake':
        return 'Earthquake Info';
      case 'flood':
        return 'Flood Report';
      case 'landslide':
        return 'Landslide Alert';
      case 'cyclone':
        return 'Cyclone Advisory';
      case 'lightning':
        return 'Lightning Alert';
      case 'coastal':
      case 'coastalWarning':
        return 'Coastal Warning';
      case 'tsunami':
        return 'Tsunami Bulletin';
      default:
        return 'Information';
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────

class _MetaRow {
  final String label;
  final String value;
  _MetaRow(this.label, this.value);
}

class _MetaRowTile extends StatelessWidget {
  final _MetaRow row;
  const _MetaRowTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                row.label,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: TextStyle(
                color: onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EventPin extends StatelessWidget {
  final Color color;
  final String label;
  const _EventPin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final pinBackdrop = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.6);
    final chipBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8FB8E0)
        : const Color(0xFFB3CDF0);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pinBackdrop,
          ),
        ),
        Icon(Icons.close, color: color, size: 32),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntensityEntry {
  final String badge;
  final String place;
  _IntensityEntry({required this.badge, required this.place});
}

class _EventReport {
  final String maxIntensity;
  final String magnitude;
  final String magnitudeLabel;
  final String dateTime;
  final String epicenter;
  final String depth;
  final String statusBadge;
  final Color statusColor;
  final String statusMessage;
  final List<_IntensityEntry> intensityEntries;

  _EventReport({
    required this.maxIntensity,
    required this.magnitude,
    required this.magnitudeLabel,
    required this.dateTime,
    required this.epicenter,
    required this.depth,
    required this.statusBadge,
    required this.statusColor,
    required this.statusMessage,
    required this.intensityEntries,
  });
}
