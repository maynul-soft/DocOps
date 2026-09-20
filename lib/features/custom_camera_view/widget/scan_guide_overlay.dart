import 'package:flutter/material.dart';

enum CameraScanMode {
  document,
  idCard,
  passport,
}

class ScanGuideOverlay extends StatelessWidget {
  final CameraScanMode mode;
  final int idCardStep; // 1 = front, 2 = back
  final bool isDetected;

  const ScanGuideOverlay({
    super.key,
    required this.mode,
    this.idCardStep = 1,
    this.isDetected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == CameraScanMode.document) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        // Calculate card box size based on mode
        double boxW;
        double boxH;

        if (mode == CameraScanMode.idCard) {
          // Standard ID Card (ISO/IEC 7810 ID-1: 1.586 : 1)
          boxW = screenW * 0.88;
          boxH = boxW / 1.586;
        } else {
          // Passport (ISO/IEC 7810 ID-3: 1.42 : 1)
          boxW = screenW * 0.90;
          boxH = boxW / 1.42;
        }

        final left = (screenW - boxW) / 2;
        final top = (screenH - boxH) / 2 - 40;
        final cutoutRect = Rect.fromLTWH(left, top, boxW, boxH);

        return Stack(
          children: [
            // Darkened cutout mask
            CustomPaint(
              size: Size(screenW, screenH),
              painter: _CutoutMaskPainter(
                cutoutRect: cutoutRect,
                cornerRadius: mode == CameraScanMode.idCard ? 16.0 : 12.0,
                borderColor: isDetected ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
            // Guide Instruction Badge & Details
            Positioned(
              top: cutoutRect.top - 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDetected ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode == CameraScanMode.idCard
                            ? Icons.badge_outlined
                            : Icons.menu_book_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode == CameraScanMode.idCard
                            ? (idCardStep == 1
                                ? 'Step 1/2: Scan Front Side'
                                : 'Step 2/2: Scan Back Side')
                            : 'Align Passport Photo Page',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Inside Overlay Guidelines
            if (mode == CameraScanMode.idCard)
              Positioned(
                top: cutoutRect.top + 20,
                left: cutoutRect.left + 20,
                child: Opacity(
                  opacity: 0.35,
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 8, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(width: 70, height: 8, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // Passport MRZ Strip at bottom of cutout
            if (mode == CameraScanMode.passport)
              Positioned(
                bottom: screenH - cutoutRect.bottom + 8,
                left: cutoutRect.left + 16,
                right: cutoutRect.left + 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'P<UTO<<<<<<<<<<<<<<<<<<<<<< MRZ CODE ZONE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CutoutMaskPainter extends CustomPainter {
  final Rect cutoutRect;
  final double cornerRadius;
  final Color borderColor;

  _CutoutMaskPainter({
    required this.cutoutRect,
    required this.cornerRadius,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutRRect = RRect.fromRectAndRadius(cutoutRect, Radius.circular(cornerRadius));
    final cutoutPath = Path()..addRRect(cutoutRRect);

    // Subtract cutout from dark background
    final maskPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(maskPath, maskPaint);

    // Draw Card Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cutoutRRect, borderPaint);

    // Corner bracket accents
    const bracketLen = 22.0;
    final accentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final l = cutoutRect.left;
    final r = cutoutRect.right;
    final t = cutoutRect.top;
    final b = cutoutRect.bottom;

    // TL
    canvas.drawLine(Offset(l, t + bracketLen), Offset(l, t), accentPaint);
    canvas.drawLine(Offset(l, t), Offset(l + bracketLen, t), accentPaint);

    // TR
    canvas.drawLine(Offset(r - bracketLen, t), Offset(r, t), accentPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + bracketLen), accentPaint);

    // BL
    canvas.drawLine(Offset(l, b - bracketLen), Offset(l, b), accentPaint);
    canvas.drawLine(Offset(l, b), Offset(l + bracketLen, b), accentPaint);

    // BR
    canvas.drawLine(Offset(r - bracketLen, b), Offset(r, b), accentPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - bracketLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _CutoutMaskPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.borderColor != borderColor;
  }
}
