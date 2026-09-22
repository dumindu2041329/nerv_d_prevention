import 'package:flutter/material.dart';

/// Minimal teardrop outline of the island — the recurring brand mark.
/// Sri Lanka's silhouette reads as a teardrop; a single stroked form
/// keeps it legible at 16px.
class IslandMark extends StatelessWidget {
  final double size;
  final Color color;

  const IslandMark({super.key, this.size = 16, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IslandPainter(color),
    );
  }
}

class _IslandPainter extends CustomPainter {
  final Color color;
  _IslandPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Teardrop: rounded southern belly tapering to a northern stem.
    final path = Path()
      ..moveTo(w * 0.50, 0.0)
      ..quadraticBezierTo(w * 0.36, h * 0.22, w * 0.28, h * 0.40)
      ..cubicTo(w * 0.12, h * 0.62, w * 0.18, h * 0.94, w * 0.50, h * 0.98)
      ..cubicTo(w * 0.82, h * 0.94, w * 0.88, h * 0.62, w * 0.72, h * 0.40)
      ..quadraticBezierTo(w * 0.64, h * 0.22, w * 0.50, 0.0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IslandPainter oldDelegate) =>
      oldDelegate.color != color;
}
