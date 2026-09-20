import 'dart:typed_data';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class TfliteService {
  static Interpreter? _interpreter;
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded;

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset('assets/models/fairscan.tflite');
      _isLoaded = true;
      Logger().i('TFLite Model loaded successfully!');
    } catch (e) {
      Logger().e('Failed to load TFLite Model: $e');
    }
  }

  /// Processes the [src] Mat (BGR/BGRA format) and returns 4 document corners
  static List<cv.Point>? detectDocument(cv.Mat src) {
    if (!_isLoaded || _interpreter == null) {
      Logger().w('TFLite Service not initialized.');
      return null;
    }

    try {
      final int origWidth = src.cols;
      final int origHeight = src.rows;

      // 1. Convert to RGB if needed (assuming incoming is BGRA or BGR)
      cv.Mat rgbMat;
      if (src.type.channels == 4) {
        rgbMat = cv.cvtColor(src, cv.COLOR_BGRA2RGB);
      } else {
        rgbMat = cv.cvtColor(src, cv.COLOR_BGR2RGB);
      }

      // 2. Resize to model input shape (256x256)
      final cv.Mat resizedMat = cv.resize(rgbMat, (256, 256));
      rgbMat.dispose();

      // 3. Normalize pixels to [0.0, 1.0] and pack into Float32List
      final Uint8List rawBytes = resizedMat.data;
      resizedMat.dispose();

      final Float32List inputBuffer = Float32List(256 * 256 * 3);
      for (int i = 0; i < rawBytes.length; i++) {
        inputBuffer[i] = rawBytes[i] / 255.0;
      }

      // 4. Run inference
      final Float32List outputBuffer = Float32List(256 * 256);
      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

      // 5. Create binary mask from outputs (threshold = 0.5)
      final Uint8List maskBytes = Uint8List(256 * 256);
      for (int i = 0; i < outputBuffer.length; i++) {
        maskBytes[i] = outputBuffer[i] > 0.5 ? 255 : 0;
      }

      // 6. Load mask into OpenCV Mat to extract contours
      final cv.Mat maskMat = cv.Mat.fromList(256, 256, cv.MatType.CV_8UC1, maskBytes);

      // Connect any slight gaps in the mask
      final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final cv.Mat closedMat = cv.morphologyEx(maskMat, cv.MORPH_CLOSE, kernel);
      maskMat.dispose();
      kernel.dispose();

      final (contours, _) = cv.findContours(
        closedMat,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );
      closedMat.dispose();

      if (contours.isEmpty) {
        return null;
      }

      // Find the contour with the largest area
      double maxArea = 0;
      cv.VecPoint? bestContour;
      for (final cont in contours) {
        final area = cv.contourArea(cont);
        if (area > maxArea) {
          maxArea = area;
          bestContour = cont;
        }
      }

      if (bestContour == null || maxArea < 1000) {
        // Minimum area threshold for valid document
        return null;
      }

      // 7. Get the 4 corners of the document boundary
      final cv.Mat hullMat = cv.convexHull(bestContour, returnPoints: true);
      final cv.VecPoint hull = cv.VecPoint.fromMat(hullMat);
      hullMat.dispose();
      final double perimeter = cv.arcLength(hull, true);

      cv.VecPoint? approx;
      for (double eps = 0.01; eps <= 0.15; eps += 0.02) {
        final tempApprox = cv.approxPolyDP(hull, eps * perimeter, true);
        if (tempApprox.length == 4) {
          approx = tempApprox;
          break;
        }
        tempApprox.dispose();
      }

      // Fallback to bounding box of the hull if approx poly doesn't yield 4 points
      if (approx == null) {
        final mRect = cv.minAreaRect(hull);
        final boxPoints = cv.boxPoints(mRect);
        approx = cv.VecPoint.fromList([
          cv.Point(boxPoints[0].x.toInt(), boxPoints[0].y.toInt()),
          cv.Point(boxPoints[1].x.toInt(), boxPoints[1].y.toInt()),
          cv.Point(boxPoints[2].x.toInt(), boxPoints[2].y.toInt()),
          cv.Point(boxPoints[3].x.toInt(), boxPoints[3].y.toInt()),
        ]);
      }
      hull.dispose();

      // 8. Scale points back to original image size
      final double scaleX = origWidth / 256.0;
      final double scaleY = origHeight / 256.0;

      final List<cv.Point> originalCorners = [];
      for (int i = 0; i < approx.length; i++) {
        final p = approx[i];
        originalCorners.add(cv.Point(
          (p.x * scaleX).toInt(),
          (p.y * scaleY).toInt(),
        ));
      }
      approx.dispose();

      // Order clockwise: TL, TR, BR, BL
      originalCorners.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
      final topLeft = originalCorners[0];
      final bottomRight = originalCorners[3];
      final remaining = [originalCorners[1], originalCorners[2]];
      remaining.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
      final topRight = remaining[1];
      final bottomLeft = remaining[0];

      return [topLeft, topRight, bottomRight, bottomLeft];
    } catch (e) {
      Logger().e('Error in TFLite document detection: $e');
      return null;
    }
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
