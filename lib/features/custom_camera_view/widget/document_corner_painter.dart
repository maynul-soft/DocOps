import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DocumentCornerPainter extends CustomPainter {
  final List<cv.Point> points;
  final Size previewSize; // Camera resolution (e.g. 720x1280)

  DocumentCornerPainter({required this.points, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Scaling Factor: Resolution theke screen size e convert korar ratio
    // Camera image sadharonoto landscape e thake, tai swap kora lagte pare
    final double scaleX = size.width / previewSize.width;
    final double scaleY = size.height / previewSize.height;

    final List<Offset> offsets = points.map((p) {
      return Offset(p.x * scaleX, p.y * scaleY);
    }).toList();

    final paint = Paint()
      ..color = Colors.deepOrange.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < offsets.length; i += 4) {
      if (i + 3 >= offsets.length) break;

      final path = Path()
        ..moveTo(offsets[i].dx, offsets[i].dy)
        ..lineTo(offsets[i + 1].dx, offsets[i + 1].dy)
        ..lineTo(offsets[i + 2].dx, offsets[i + 2].dy)
        ..lineTo(offsets[i + 3].dx, offsets[i + 3].dy)
        ..close();

      // Box ta draw kora
      canvas.drawPath(path, paint);

      // Corner circles - Premium Avatar Style
      final cornerPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int j = 0; j < 4; j++) {
        final p1 = offsets[i + j];
        final p2 = offsets[i + (j + 1) % 4];
        final midpoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

        // Draw Corner Dots
        canvas.drawCircle(p1, 10, cornerPaint);
        canvas.drawCircle(p1, 10, dotBorderPaint);

        // Draw Midpoint Dots (Professional Look)
        canvas.drawCircle(midpoint, 8, cornerPaint);
        canvas.drawCircle(midpoint, 8, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DocumentCornerPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
