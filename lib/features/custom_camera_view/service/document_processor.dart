import 'dart:isolate';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

class DocumentCorners {
  final cv.Point topLeft;
  final cv.Point topRight;
  final cv.Point bottomLeft;
  final cv.Point bottomRight;

  DocumentCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
}

class DocumentProcessor {
 
  static Future<DocumentCorners?> detectDocumentCorners(cv.Mat mat) async {
    try {
      
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // Gaussian Blur
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);

      // Canny Edge Detection
      final edges = cv.canny(blurred, 75, 200);

      // Contour খোঁজো
      final (contours, _) = cv.findContours(
        edges,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );

      cv.VecPoint? bestContour;
      double maxArea = 0;

      for (final contour in contours) {
        final area = cv.contourArea(contour);
        if (area > maxArea) {
          maxArea = area;
          bestContour = contour;
        }
      }

      // Memory free করো
      gray.dispose();
      blurred.dispose();
      edges.dispose();
      mat.dispose(); // ✅ এখানে dispose করো

      if (bestContour == null || maxArea < 1000) return null;

      final peri = cv.arcLength(bestContour, true);
      final approx = cv.approxPolyDP(bestContour, 0.02 * peri, true);

      if (approx.length != 4) return null;

      final points = approx.toList();
      points.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));

      final topLeft = points[0];
      final bottomRight = points[3];
      final remaining = [points[1], points[2]];
      remaining.sort((a, b) => a.x.compareTo(b.x));
      final bottomLeft = remaining[0];
      final topRight = remaining[1];

      return DocumentCorners(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      );
    } catch (e) {
      Logger().e('Corner detection error: $e');
      return null;
    }
  }

  
  static Future<String?> processDocument({
    required String imagePath,
    required DocumentCorners corners,
    required bool applyBW, // Black & White filter
  }) async {
    return await Isolate.run(() async {
      final imageBytes = await File(imagePath).readAsBytes();
      final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);

      // Source points — detected corners
      final srcPoints = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, [
        corners.topLeft.x.toDouble(),
        corners.topLeft.y.toDouble(),
        corners.topRight.x.toDouble(),
        corners.topRight.y.toDouble(),
        corners.bottomRight.x.toDouble(),
        corners.bottomRight.y.toDouble(),
        corners.bottomLeft.x.toDouble(),
        corners.bottomLeft.y.toDouble(),
      ]);

      
      const outputWidth = 595.0;
      const outputHeight = 842.0;

      
      final dstPoints = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, [
        0.0,
        0.0,
        outputWidth,
        0.0,
        outputWidth,
        outputHeight,
        0.0,
        outputHeight,
      ]);

      // Perspective Transform Matrix বের করো
      final transformMatrix = cv.getPerspectiveTransform(
        srcPoints as cv.VecPoint,
        dstPoints as cv.VecPoint,
      );

      // Transform apply করো — document সোজা হবে
      final warped = cv.warpPerspective(mat, transformMatrix, (
        outputWidth.toInt(),
        outputHeight.toInt(),
      ));

      // Black & White filter apply করো (optional)
      cv.Mat finalImage;
      if (applyBW) {
        final gray = cv.cvtColor(warped, cv.COLOR_BGR2GRAY);
        // Adaptive threshold — scanner effect দেবে
        finalImage = cv.adaptiveThreshold(
          gray,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY,
          11,
          2,
        );
      } else {
        finalImage = warped;
      }

      // File এ save করো
      final dir = await getApplicationDocumentsDirectory();
      final outputPath =
          '${dir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.jpg';

      cv.imwrite(outputPath, finalImage);

      // Memory free করো
      mat.dispose();
      srcPoints.dispose();
      dstPoints.dispose();
      transformMatrix.dispose();
      warped.dispose();
      if (applyBW) finalImage.dispose();

      return outputPath;
    });
  }

  // ✅ ধাপ ৩ — Multiple images থেকে PDF বানাও
  static Future<String?> createPDF(List<String> imagePaths) async {
    try {
      final pdfDoc = pw.Document();

      for (final path in imagePaths) {
        final imageBytes = await File(path).readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdfDoc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) =>
                pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
          ),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final outputPath =
          '${dir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(outputPath);
      await file.writeAsBytes(await pdfDoc.save());

      return outputPath;
    } catch (e) {
      return null;
    }
  }
}
