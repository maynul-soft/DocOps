import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DocumentCornerPainter extends CustomPainter {
  final List<cv.Point> points;
  final Size previewSize; // Camera frame resolution

  DocumentCornerPainter({
    required this.points,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Scaling Factor: convert camera resolution coordinates to canvas screen coordinates
    final double scaleX = size.width / previewSize.width;
    final double scaleY = size.height / previewSize.height;

    final List<Offset> offsets = points.map((p) {
      return Offset(p.x * scaleX, p.y * scaleY);
    }).toList();

    for (int i = 0; i < offsets.length; i += 4) {
      if (i + 3 >= offsets.length) break;

      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final p2 = offsets[i + 2];
      final p3 = offsets[i + 3];

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      // 1. Shaded Tint Fill — clearly highlights the detected document area
      final fillPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Subtle inner gradient glow for depth
      final glowPaint = Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;
      canvas.drawPath(path, glowPaint);

      // 2. Bold Perimeter Border (Garo/Bold Border)
      final borderPaint = Paint()
        ..color = const Color(0xFF1D4ED8)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);

      // 3. Professional Corner Brackets & Markers
      final cornerList = [p0, p1, p2, p3];
      for (int j = 0; j < 4; j++) {
        final current = cornerList[j];
        final prev = cornerList[(j + 3) % 4];
        final next = cornerList[(j + 1) % 4];

        _drawCornerBracket(canvas, current, prev, next);

        // Center dot with ring
        final outerRing = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(current, 7, outerRing);

        final innerDot = Paint()
          ..color = const Color(0xFF1D4ED8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(current, 4.5, innerDot);

        // Draw midpoint alignment pill
        final midpoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        _drawMidpointMarker(canvas, midpoint);
      }
    }
  }

  void _drawCornerBracket(Canvas canvas, Offset corner, Offset pA, Offset pB) {
    const double bracketLength = 22.0;

    final vecA = (pA - corner);
    final distA = vecA.distance;
    final unitA = distA > 0 ? vecA / distA : Offset.zero;

    final vecB = (pB - corner);
    final distB = vecB.distance;
    final unitB = distB > 0 ? vecB / distB : Offset.zero;

    final bracketPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final armA = corner + (unitA * math.min(bracketLength, distA * 0.4));
    final armB = corner + (unitB * math.min(bracketLength, distB * 0.4));

    final cornerPath = Path()
      ..moveTo(armA.dx, armA.dy)
      ..lineTo(corner.dx, corner.dy)
      ..lineTo(armB.dx, armB.dy);

    canvas.drawPath(cornerPath, bracketPaint);
  }

  void _drawMidpointMarker(Canvas canvas, Offset midpoint) {
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(midpoint, 5, ringPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(midpoint, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant DocumentCornerPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
