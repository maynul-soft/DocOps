import 'dart:typed_data';
// ignore: library_prefixes
import 'dart:math' as Math;
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/model/processed_image_model.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class TestOpenCv {
  static Uint8List? processAndWarp(cv.Mat src, List<cv.Point> points) {
    if (points.length != 4) return null;

    // 1. Sort points: TL, TR, BR, BL
    final sorted = _sortPoints(points);
    final tl = sorted[0];
    final tr = sorted[1];
    final br = sorted[2];
    final bl = sorted[3];

    // 2. Calculate target width and height
    final widthA = Math.sqrt(
      Math.pow(br.x - bl.x, 2) + Math.pow(br.y - bl.y, 2),
    );
    final widthB = Math.sqrt(
      Math.pow(tr.x - tl.x, 2) + Math.pow(tr.y - tl.y, 2),
    );
    final maxWidth = Math.max(widthA, widthB).toInt();

    final heightA = Math.sqrt(
      Math.pow(tr.x - br.x, 2) + Math.pow(tr.y - br.y, 2),
    );
    final heightB = Math.sqrt(
      Math.pow(tl.x - bl.x, 2) + Math.pow(tl.y - bl.y, 2),
    );
    final maxHeight = Math.max(heightA, heightB).toInt();

    final srcPoints = cv.VecPoint.fromList(sorted);
    final dstPoints = cv.VecPoint.fromList([
      cv.Point(0, 0),
      cv.Point(maxWidth - 1, 0),
      cv.Point(maxWidth - 1, maxHeight - 1),
      cv.Point(0, maxHeight - 1),
    ]);

    // 3. Perspective Warp
    final m = cv.getPerspectiveTransform(srcPoints, dstPoints);
    final warped = cv.warpPerspective(src, m, (maxWidth, maxHeight));

    // 4. Magic Color Enhancement (CamScanner Style)
    final enhanced = applyMagicColor(warped);

    final (_, encoded) = cv.imencode('.jpg', enhanced);

    // Cleanup
    srcPoints.dispose();
    dstPoints.dispose();
    m.dispose();
    warped.dispose();
    enhanced.dispose();

    return encoded;
  }

  static cv.Mat applyMagicColor(cv.Mat src) {
    // Noise Reduction
    final blurred = cv.gaussianBlur(src, (3, 3), 0);

    // Increase contrast and brightness (Magic Color effect)
    // Alpha (contrast) 1.2, Beta (brightness) 10
    final adjusted = src.convertTo(src.type, alpha: 1.2, beta: 10);

    // Sharpening
    final kernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
      0.0, -1.0, 0.0,
      -1.0, 5.0, -1.0,
      0.0, -1.0, 0.0,
    ]);
    final sharpened = cv.filter2D(adjusted, -1, kernel);

    blurred.dispose();
    adjusted.dispose();
    kernel.dispose();

    return sharpened;
  }

  static List<cv.Point> _sortPoints(List<cv.Point> pts) {
    final sorted = List<cv.Point>.from(pts);
    // Sort by Y to find Top vs Bottom
    sorted.sort((a, b) => a.y.compareTo(b.y));
    final top = sorted.sublist(0, 2);
    final bottom = sorted.sublist(2, 4);

    // Sort Top points by X to find TL vs TR
    top.sort((a, b) => a.x.compareTo(b.x));
    final tl = top[0];
    final tr = top[1];

    // Sort Bottom points by X to find BL vs BR
    bottom.sort((a, b) => a.x.compareTo(b.x));
    final bl = bottom[0];
    final br = bottom[1];

    return [tl, tr, br, bl];
  }

  static cv.Mat convertImageToMat(CameraImage image) {
    final allBytes = BytesBuilder();

    // marge all image plane (YUV)

    for (final plane in image.planes) {
      allBytes.add(plane.bytes);
    }

    final bytes = allBytes.toBytes();
    final yuvMat = cv.Mat.fromList(
      (image.height * 1.5).toInt(),
      image.width,
      cv.MatType.CV_8UC1,
      bytes,
    );

    // convert to bgr
    final bgrMat = cv.cvtColor(yuvMat, cv.COLOR_YUV2BGRA_NV21);

    // Rotate 90 degrees clockwise for Android portrait mode
    final rotatedMat = cv.rotate(bgrMat, cv.ROTATE_90_CLOCKWISE);

    yuvMat.dispose();
    bgrMat.dispose();

    return rotatedMat;
  }

  static List<cv.Point>? processDocuments(
    cv.Mat src, {
    bool isTestMode = false,
  }) {
    // Optimization: Resize large images for faster detection

    // Optimization: Resize to 360px for real-time sub-10ms streaming detection
    final targetSize = 360;
    double scale = 1.0;
    cv.Mat detectionMat = src;

    if (src.cols > targetSize || src.rows > targetSize) {
      scale = targetSize / Math.max(src.cols, src.rows);
      detectionMat = cv.resize(src, (0, 0), fx: scale, fy: scale);
    }

    // 1. Grayscale & Fast Gaussian Blur (15x faster than bilateral filter)
    final gray = cv.cvtColor(detectionMat, cv.COLOR_BGR2GRAY);
    final blurred = cv.gaussianBlur(gray, (5, 5), 0);
    gray.dispose();
    if (detectionMat != src) detectionMat.dispose();

    cv.VecPoint? bestApprox;
    cv.VecPoint? globalLargestContour;
    double globalMaxArea = 0;
    final imageArea = src.rows * src.cols;

    // Fast 2-tier edge detection: Canny primary, Adaptive threshold fallback
    for (int strategy = 0; strategy < 2; strategy++) {
      cv.Mat edges;
      if (strategy == 0) {
        // Strategy 1: Fast Canny
        edges = cv.canny(blurred, 50, 150);
      } else {
        // Strategy 2: Adaptive Threshold (only if Canny found nothing)
        if (bestApprox != null) break;
        edges = cv.adaptiveThreshold(
          blurred,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY,
          17,
          3,
        );
      }

      // Connect broken edges
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);

      // Find Contours
      final (contours, _) = cv.findContours(
        closed,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );

      final imgCenter = cv.Point(src.cols ~/ 2, src.rows ~/ 2);
      double bestScore = -1.0;

      for (final cont in contours) {
        final area = cv.contourArea(cont);

        if (area < imageArea * 0.05 || area > imageArea * 0.95) {
          continue;
        }

        // Track the absolute largest contour as a fallback
        if (area > globalMaxArea) {
          globalMaxArea = area;
          globalLargestContour?.dispose();
          globalLargestContour = cont.clone();
        }

        // Calculate Centering Score: favor objects in the middle
        final rect = cv.boundingRect(cont);
        final contCenter = cv.Point(
          rect.x + rect.width ~/ 2,
          rect.y + rect.height ~/ 2,
        );
        final dist = Math.sqrt(
          Math.pow(contCenter.x - imgCenter.x, 2) +
              Math.pow(contCenter.y - imgCenter.y, 2),
        );
        final maxDist =
            Math.sqrt(Math.pow(src.cols, 2) + Math.pow(src.rows, 2)) / 2;
        final proximity = 1.0 - (dist / maxDist).clamp(0.0, 1.0);

        // Final Score: Combining area and centering
        final score = area * (1.0 + proximity * 0.3);

        if (score > bestScore) {
          bestScore = score;

          final hullMat = cv.convexHull(cont, returnPoints: true);
          final hull = cv.VecPoint.fromMat(hullMat);
          hullMat.dispose();
          final perimeter = cv.arcLength(hull, true);

          bool found = false;
          for (double eps = 0.01; eps <= 0.15; eps += 0.02) {
            final approx = cv.approxPolyDP(hull, eps * perimeter, true);
            if (approx.length == 4) {
              bestApprox?.dispose();
              bestApprox = approx.clone();
              found = true;
              approx.dispose();
              break;
            }
            approx.dispose();
          }

          if (!found && area > imageArea * 0.2) {
            final mRect = cv.minAreaRect(hull);
            final boxPoints = cv.boxPoints(mRect);
            bestApprox?.dispose();
            bestApprox = cv.VecPoint.fromList([
              cv.Point(boxPoints[0].x.toInt(), boxPoints[0].y.toInt()),
              cv.Point(boxPoints[1].x.toInt(), boxPoints[1].y.toInt()),
              cv.Point(boxPoints[2].x.toInt(), boxPoints[2].y.toInt()),
              cv.Point(boxPoints[3].x.toInt(), boxPoints[3].y.toInt()),
            ]);
          }
          hull.dispose();
        }
      }

      edges.dispose();
      kernel.dispose();
      closed.dispose();
    }

    // Fallback if no 4-point approximation was found
    if (bestApprox == null && globalLargestContour != null) {
      final rect = cv.boundingRect(globalLargestContour);
      bestApprox = cv.VecPoint.fromList([
        cv.Point(rect.x, rect.y),
        cv.Point(rect.x + rect.width, rect.y),
        cv.Point(rect.x + rect.width, rect.y + rect.height),
        cv.Point(rect.x, rect.y + rect.height),
      ]);
    }

    if (bestApprox != null) {
      final pts = <cv.Point>[];
      for (int i = 0; i < bestApprox.length; i++) {
        pts.add(bestApprox[i]);
      }

      // Order clockwise: TL, TR, BR, BL
      pts.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
      final topLeft = pts[0];
      final bottomRight = pts[3];
      final remaining = [pts[1], pts[2]];
      remaining.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
      final topRight = remaining[1];
      final bottomLeft = remaining[0];

      final List<cv.Point> orderedCorners = [
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
      ];

      // Edge Snapping Logic (for partial/expanded documents)
      const margin = 15;
      const snapThreshold = 25; // Snap if within 25px of edge
      final w = src.cols;
      final h = src.rows;

      final snappedCorners = orderedCorners.map((p) {
        int nx = p.x;
        int ny = p.y;

        if (nx < snapThreshold) nx = margin;
        if (nx > w - snapThreshold) nx = w - margin;
        if (ny < snapThreshold) ny = margin;
        if (ny > h - snapThreshold) ny = h - margin;

        return cv.Point(nx, ny);
      }).toList();

      if (isTestMode) {
        final resultMat = src.clone();
        cv.drawContours(
          resultMat,
          cv.VecVecPoint.fromList([
            snappedCorners
                .map(
                  (p) => cv.Point((p.x * scale).toInt(), (p.y * scale).toInt()),
                )
                .toList(),
          ]),
          -1,
          cv.Scalar(255, 0, 0, 255), // Blue in BGR
          thickness: 5,
        );
        encodeImage(resultMat, 'Detected Document');
        resultMat.dispose();
      }

      bestApprox.dispose();
      globalLargestContour?.dispose();
      blurred.dispose();

      // Scale points back to original size
      return snappedCorners
          .map((p) => cv.Point((p.x / scale).toInt(), (p.y / scale).toInt()))
          .toList();
    }

    globalLargestContour?.dispose();
    blurred.dispose();

    debugPrint('❌ No document corners found');
    return null;
  }

  static Future<void> encodeImage(cv.Mat mat, String title) async {
    final (success, bytes) = cv.imencode('.jpg', mat);

    if (!success) {
      Logger().e('Filed to image encode');
    } else {
      if (Get.isRegistered<CustomCameraController>()) {
        Get.find<CustomCameraController>().addImagesForProcessedList(
          ProcessedImageModel(bytes: bytes, title: title),
        );
      }
    }
  }
}
