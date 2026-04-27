import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/service/document_processor.dart';

class DocumentCornerPainter extends CustomPainter {
  final DocumentCorners corners;
  final Size imageSize;
  final Size screenSize;

  DocumentCornerPainter({
    required this.corners,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
   
    final bool isRotated = imageSize.width < imageSize.height == false;

    final double imgW = isRotated ? imageSize.height : imageSize.width;
    final double imgH = isRotated ? imageSize.width : imageSize.height;

    final double scaleX = screenSize.width / imgW;
    final double scaleY = screenSize.height / imgH;

    
    Offset scaled(cvPoint) {
      return Offset(
        cvPoint.x * scaleX,
        cvPoint.y * scaleY,
      );
    }

    final tl = scaled(corners.topLeft);
    final tr = scaled(corners.topRight);
    final bl = scaled(corners.bottomLeft);
    final br = scaled(corners.bottomRight);

    
    final fillPaint = Paint()
      ..color = Colors.green.withAlpha(50)
      ..style = PaintingStyle.fill;

    // ✅ সবুজ border
    final borderPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // ✅ Path আঁকো
    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // ✅ Corner এ circle আঁকো
    final circlePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final circleBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in [tl, tr, bl, br]) {
      canvas.drawCircle(point, 10, circlePaint);
      canvas.drawCircle(point, 10, circleBorderPaint);
    }

    
  }

  @override
  bool shouldRepaint(DocumentCornerPainter old) =>
      old.corners != corners ||
      old.imageSize != imageSize ||
      old.screenSize != screenSize;
}