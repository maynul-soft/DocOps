import 'dart:io';
import 'dart:typed_data';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

enum DocFilterType {
  original,
  magicColor,
  totalBw,
  grayscale,
  brighten,
  sharpen,
}

class DocFilterService {
  /// Applies one of the popular document scanner filters to the input image file
  /// and writes the processed output to [outputPath] (or overwrites if same).
  static Future<bool> applyFilterToFile({
    required String inputPath,
    required String outputPath,
    required DocFilterType filterType,
  }) async {
    try {
      final file = File(inputPath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final filteredBytes = await applyFilterToBytes(
        inputBytes: bytes,
        filterType: filterType,
      );

      if (filteredBytes == null) return false;

      final outFile = File(outputPath);
      await outFile.writeAsBytes(filteredBytes);
      return true;
    } catch (e) {
      Logger().e('Error applying filter to file: $e');
      return false;
    }
  }

  /// Processes raw image bytes with the selected filter using OpenCV
  static Future<Uint8List?> applyFilterToBytes({
    required Uint8List inputBytes,
    required DocFilterType filterType,
  }) async {
    if (filterType == DocFilterType.original) {
      return inputBytes;
    }

    final mat = cv.imdecode(inputBytes, cv.IMREAD_COLOR);
    if (mat.isEmpty) {
      mat.dispose();
      return null;
    }

    cv.Mat? processed;

    try {
      switch (filterType) {
        case DocFilterType.original:
          processed = mat.clone();
          break;

        case DocFilterType.magicColor:
          // CamScanner signature Magic Color: enhanced contrast + brightness + unsharp mask
          final blurred = cv.gaussianBlur(mat, (3, 3), 0);
          final adjusted = blurred.convertTo(blurred.type, alpha: 1.25, beta: 12);
          blurred.dispose();

          final kernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
            0.0, -0.8, 0.0,
            -0.8, 4.2, -0.8,
            0.0, -0.8, 0.0,
          ]);
          processed = cv.filter2D(adjusted, -1, kernel);
          adjusted.dispose();
          kernel.dispose();
          break;

        case DocFilterType.totalBw:
          // Total Black & White (Document Photocopy): crisp pure black text on pure white paper
          final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
          final blurredGray = cv.gaussianBlur(gray, (3, 3), 0);
          final bw = cv.adaptiveThreshold(
            blurredGray,
            255,
            cv.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv.THRESH_BINARY,
            21,
            11,
          );
          processed = cv.cvtColor(bw, cv.COLOR_GRAY2BGR);
          gray.dispose();
          blurredGray.dispose();
          bw.dispose();
          break;

        case DocFilterType.grayscale:
          // Smooth 256-level grayscale
          final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
          processed = cv.cvtColor(gray, cv.COLOR_GRAY2BGR);
          gray.dispose();
          break;

        case DocFilterType.brighten:
          // Gentle shadow removal and paper brightening
          processed = mat.convertTo(mat.type, alpha: 1.15, beta: 32);
          break;

        case DocFilterType.sharpen:
          // High-pass sharpening for fine fonts and blurry captures
          final kernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
            -1.0, -1.0, -1.0,
            -1.0,  9.0, -1.0,
            -1.0, -1.0, -1.0,
          ]);
          processed = cv.filter2D(mat, -1, kernel);
          kernel.dispose();
          break;
      }

      final (success, encoded) = cv.imencode('.jpg', processed);
      if (success) {
        return encoded;
      }
      return null;
    } catch (e) {
      Logger().e('Error in applyFilterToBytes: $e');
      return null;
    } finally {
      mat.dispose();
      processed?.dispose();
    }
  }
}
