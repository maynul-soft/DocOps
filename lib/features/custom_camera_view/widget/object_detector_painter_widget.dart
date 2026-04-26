import 'package:doc_scanner/core/export_path/export_path.dart';

class ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final Size screenSize;

  ObjectDetectorPainter({
    required this.objects,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Paint bgPaint = Paint()
      ..color = Colors.blue.withAlpha(60)
      ..style = PaintingStyle.fill;

    for (final DetectedObject detectedObject in objects) {
      // ইমেজ সাইজ থেকে স্ক্রিন সাইজে স্কেল করো
      final double scaleX = screenSize.width / imageSize.width;
      final double scaleY = screenSize.height / imageSize.height;

      final Rect scaledRect = Rect.fromLTRB(
        detectedObject.boundingBox.left * scaleX,
        detectedObject.boundingBox.top * scaleY,
        detectedObject.boundingBox.right * scaleX,
        detectedObject.boundingBox.bottom * scaleY,
      );

      // বক্স আঁকো
      canvas.drawRect(scaledRect, bgPaint);
      canvas.drawRect(scaledRect, boxPaint);

      // Label দেখাও
      if (detectedObject.labels.isNotEmpty) {
        final label = detectedObject.labels
            .reduce((a, b) => a.confidence > b.confidence ? a : b);

        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${label.text} ${(label.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.blue,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(scaledRect.left + 4, scaledRect.top + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ObjectDetectorPainter oldDelegate) {
    return oldDelegate.objects != objects;
  }
}