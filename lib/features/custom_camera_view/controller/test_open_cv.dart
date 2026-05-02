import 'dart:typed_data';
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

    // 4. Black and White Enhancement (Professional Scanner Look)
    final gray = cv.cvtColor(warped, cv.COLOR_BGR2GRAY);

    final bw = cv.adaptiveThreshold(
      gray,
      255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY,
      31,
      15,
    );

    final (_, encoded) = cv.imencode('.jpg', bw);

    // Cleanup
    srcPoints.dispose();
    dstPoints.dispose();
    m.dispose();
    warped.dispose();
    gray.dispose();
    bw.dispose();

    return encoded;
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

    debugPrint('All bytes ====== $allBytes');

    //make as byte

    final bytes = allBytes.toBytes();

    //convert to yovMat

    final yuvMat = cv.Mat.fromList(
      (image.height * 1.5).toInt(),
      image.width,
      cv.MatType.CV_8UC1,
      bytes,
    );

    debugPrint('yuvMat ====== $allBytes');

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
    final originalSize = Size(src.cols.toDouble(), src.rows.toDouble());
    double scale = 1.0;
    cv.Mat detectionMat = src;

    if (src.cols > 1000 || src.rows > 1000) {
      scale = 1000 / Math.max(src.cols, src.rows);
      detectionMat = cv.resize(src, (0, 0), fx: scale, fy: scale);
    }

    // 1. Grayscale
    final gray = cv.cvtColor(detectionMat, cv.COLOR_BGR2GRAY);

    // Low Light Contrast Enhancement (CLAHE)
    final clahe = cv.createCLAHE(clipLimit: 3.0, tileGridSize: (8, 8));
    final enhancedGray = clahe.apply(gray);
    clahe.dispose();

    if (isTestMode) encodeImage(enhancedGray, 'CLAHE Contrast');

    // 2. Noise Reduction
    final blurred = cv.gaussianBlur(enhancedGray, (9, 9), 0);
    final filtered = cv.bilateralFilter(blurred, 9, 75, 75);
    enhancedGray.dispose();
    gray.dispose();
    if (detectionMat != src) detectionMat.dispose();
    if (isTestMode) encodeImage(filtered, 'Bilateral Filter');

    cv.VecPoint? bestApprox;
    cv.VecPoint? globalLargestContour;
    double maxArea = 0;
    double globalMaxArea = 0;
    final imageArea = src.rows * src.cols;

    // Try multiple edge detection strategies to ensure we find the document
    for (int strategy = 0; strategy < 3; strategy++) {
      cv.Mat edges;
      if (strategy == 0) {
        // Strategy 1: Standard Canny
        edges = cv.canny(filtered, 75, 200);
      } else if (strategy == 1) {
        // Strategy 2: Adaptive Threshold
        edges = cv.adaptiveThreshold(
          filtered,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY,
          21, // Increased block size for low light
          2,
        );
      } else {
        // Strategy 3: Otsu Thresholding then Canny
        final (_, threshMat) = cv.threshold(
          filtered,
          0,
          255,
          cv.THRESH_BINARY | cv.THRESH_OTSU,
        );
        edges = cv.canny(threshMat, 50, 150);
        threshMat.dispose();
      }

      // Connect broken edges (stronger kernel for ring diaries/spirals)
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (7, 7));
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
      filtered.dispose();
      blurred.dispose();

      // Scale points back to original size
      return snappedCorners
          .map((p) => cv.Point((p.x / scale).toInt(), (p.y / scale).toInt()))
          .toList();
    }

    globalLargestContour?.dispose();
    blurred.dispose();
    filtered.dispose();

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

  // static List<cv.Point>? processDocuments(cv.Mat src) {
  //   // Make grayscale

  //   final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);

  //   debugPrint('gray ====== $gray');

  //   // make blur

  //   final blurred = cv.gaussianBlur(gray, (5, 5), 0);

  //   debugPrint('blurred ====== $blurred');

  //   // Canny edge detection

  //   final canny = cv.canny(blurred, 75, 200);

  //   debugPrint('canny ====== $canny');

  //   // Contours

  //   final (contours, _) = cv.findContours(
  //     canny,
  //     cv.RETR_EXTERNAL,
  //     cv.CHAIN_APPROX_SIMPLE,
  //   );

  //   debugPrint('contours ====== $contours');

  //   cv.VecPoint? largeCounter;
  //   double maxArea = 0;

  //   //find the biggest shape

  //   for (final cont in contours) {
  //     final area = cv.contourArea(cont);

  //     if (area > 1000) {
  //       final perimeter = cv.arcLength(cont, true);

  //       final approx = cv.approxPolyDP(cont, 0.02 * perimeter, true);

  //       if (approx.length == 4 && area > maxArea) {
  //         largeCounter?.dispose();
  //         largeCounter = approx;
  //         maxArea = area;

  //         debugPrint('approx ====== $approx');
  //       } else {
  //         approx.dispose();
  //       }
  //     }
  //   }

  //   gray.dispose();
  //   canny.dispose();
  //   blurred.dispose();

  //   if (largeCounter != null && largeCounter.isNotEmpty) {
  //     final points = <cv.Point>[];
  //     for (int i = 0; i < largeCounter.length; i++) {
  //       points.add(largeCounter[i]);
  //     }

  //     largeCounter.dispose();

  //     debugPrint('points ====== $points');

  //     return points;
  //   }
  //   return null;
  // }
}
