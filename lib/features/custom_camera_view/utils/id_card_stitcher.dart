import 'dart:io';
import 'dart:ui' as ui;
import 'package:doc_scanner/core/export_path/export_path.dart';

class IdCardStitcher {
  /// Stitches Front and Back ID Card images onto a clean single A4 sheet
  static Future<String?> stitchIdCard({
    required String frontPath,
    required String backPath,
  }) async {
    try {
      final frontBytes = await File(frontPath).readAsBytes();
      final backBytes = await File(backPath).readAsBytes();

      final frontCodec = await ui.instantiateImageCodec(frontBytes);
      final frontFrame = await frontCodec.getNextFrame();
      final frontImage = frontFrame.image;

      final backCodec = await ui.instantiateImageCodec(backBytes);
      final backFrame = await backCodec.getNextFrame();
      final backImage = backFrame.image;

      // A4 Canvas Dimensions (high-resolution: 1600 x 2262)
      const canvasWidth = 1600.0;
      const canvasHeight = 2262.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));

      // 1. White Background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        Paint()..color = Colors.white,
      );

      // 2. Card Dimensions on A4
      // Standard ID-1 ratio is 1.586 : 1
      const cardWidth = 1200.0;
      const cardHeight = cardWidth / 1.586; // ~756.6
      const cardX = (canvasWidth - cardWidth) / 2; // 200.0

      const frontY = 220.0;
      final backY = frontY + cardHeight + 200.0; // ~1176.6

      final borderPaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw Front Card
      final frontRect = Rect.fromLTWH(cardX, frontY, cardWidth, cardHeight);
      final frontRRect = RRect.fromRectAndRadius(frontRect, const Radius.circular(24));

      canvas.save();
      canvas.clipRRect(frontRRect);
      paintImage(
        canvas: canvas,
        rect: frontRect,
        image: frontImage,
        fit: BoxFit.cover,
      );
      canvas.restore();
      canvas.drawRRect(frontRRect, borderPaint);

      // Draw Front Label
      _drawCardLabel(canvas, label: 'FRONT', origin: Offset(cardX, frontY - 32));

      // Draw Back Card
      final backRect = Rect.fromLTWH(cardX, backY, cardWidth, cardHeight);
      final backRRect = RRect.fromRectAndRadius(backRect, const Radius.circular(24));

      canvas.save();
      canvas.clipRRect(backRRect);
      paintImage(
        canvas: canvas,
        rect: backRect,
        image: backImage,
        fit: BoxFit.cover,
      );
      canvas.restore();
      canvas.drawRRect(backRRect, borderPaint);

      // Draw Back Label
      _drawCardLabel(canvas, label: 'BACK', origin: Offset(cardX, backY - 32));

      // 3. Render and save to disk
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final fileName = 'id_card_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = await ExportPath.saveImageToDir(
        byteData.buffer.asUint8List(),
        fileName,
      );

      // Clean up frames
      frontImage.dispose();
      backImage.dispose();

      return savedPath;
    } catch (e) {
      Logger().e('Error stitching ID card: $e');
      return null;
    }
  }

  static void _drawCardLabel(Canvas canvas, {required String label, required Offset origin}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, origin);
  }
}
