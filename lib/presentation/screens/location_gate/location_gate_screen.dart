import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../data/local/hive/hive_service.dart';
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/island_mark.dart';

class LocationGateScreen extends StatefulWidget {
  const LocationGateScreen({super.key});

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen>
    with WidgetsBindingObserver {
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _processing) {
      _recheckLocationService();
    }
  }

  Future<void> _recheckLocationService() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (enabled) {
      setState(() => _processing = false);
      _finishAndGoHome();
    }
  }

  Future<void> _handleEnable() async {
    setState(() => _processing = true);

    // Respect the permission result instead of blindly proceeding. This gate
    // is the entry path for the whole Local mode, so a denial here otherwise
    // funnels into the bloc's "no GPS" branch. A soft gate still lets the
    // user continue to Island-wide mode — we only guide, never hard-block.
    final permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.deniedForever) {
      final opened = await Geolocator.openAppSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A1A1A),
          content: Text(
            opened
                ? 'Location permission is off. Grant it in app settings, or '
                    'continue in Island-wide mode.'
                : 'Location permission denied. You can change it later, or '
                    'use Island-wide mode.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF0F2F8)),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() => _processing = false);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      final opened = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          title: Text(
            'Location Service Off',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF0F2F8),
            ),
          ),
          content: Text(
            'Your device\'s location service is turned off. Please enable '
            'it in system settings to use location-based features.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF8B95B0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B95B0),
              ),
              child: Text(
                'Continue Anyway',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: const Color(0xFF000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Open Settings',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (opened == true) {
        final rechecked = await Geolocator.isLocationServiceEnabled();
        if (!mounted) return;
        if (rechecked) {
          setState(() => _processing = false);
          _finishAndGoHome();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Text(
              'Location service still off. You can enable it later in settings.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFF0F2F8),
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }

    setState(() => _processing = false);
    _finishAndGoHome();
  }

  Future<void> _handleSkip() async {
    _finishAndGoHome();
  }

  Future<void> _finishAndGoHome() async {
    await getIt<HiveService>().setSetting('location_gate_acknowledged', true);
    AppRouter.markGatePassed();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF00BCD4);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Severity ladder strip (deck signature).
            Row(
              children: [
                for (final level in NervStyles.ladder)
                  Expanded(child: Container(height: 2, color: level.color)),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    IslandMark(size: 72, color: accent),
                    const SizedBox(height: 20),
                    Eyebrow('NERV — SRI LANKA', color: const Color(0xFF8B95B0)),
                    const SizedBox(height: 14),
                    Text(
                      'Enable Location Access',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0F2F8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your location helps deliver personalised disaster '
                      'alerts, local weather forecasts, and real-time hazard '
                      'maps for your area.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF8B95B0),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _processing ? null : _handleEnable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: const Color(0xFF000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF000000),
                                ),
                              )
                            : Text(
                                'ENABLE LOCATION',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _processing ? null : _handleSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8B95B0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'SKIP',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
