import 'package:flutter/services.dart';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/controller/test_open_cv.dart';
import 'package:doc_scanner/features/custom_camera_view/model/flash_model.dart';
import 'package:doc_scanner/features/custom_camera_view/model/processed_image_model.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:doc_scanner/core/services/tflite/tflite_service.dart';

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  List<String> capturedImages = [];
  String hiveBoxName = 'customCameraController';
  String flashMoodKey = 'Flush Mood Key';
  FlashMode flashMode = FlashMode.auto;
  bool isProcessBusy = false;
  Size? imageSize;
  bool isCapturing = false;
  bool isCameraScreenOn = true;
  List<cv.Point>? corners;
  List<List<cv.Point>> cornerBuffer = [];
  static const int bufferSize = 5;

  // Auto-Capture Mode
  bool isAutoCapture = true;
  double autoCaptureProgress = 0.0;
  DateTime? _stableSince;
  DateTime? _lastAutoCaptureTime;
  List<cv.Point>? _prevCorners;

  void toggleAutoCapture(bool enabled) {
    isAutoCapture = enabled;
    autoCaptureProgress = 0.0;
    _stableSince = null;
    update();
  }

  bool isFlashing = false;
  bool isSavingDoc = false;

  List<ProcessedImageModel> processedImageForTest = [];

  int currentCapturedPage = 0;

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();

      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await cameraController!.initialize();

      FlashMode flashMod = await getFlashMood();
      flashMode = flashMod;
      await cameraController!.setFlashMode(flashMod);
      update();

      cameraController!.startImageStream((CameraImage image) {
        if (isProcessBusy || !isCameraScreenOn) return;

        // Note: the Mat is rotated 90 degrees in TestOpenCv, so swap width and height
        imageSize = Size(image.height.toDouble(), image.width.toDouble());

        isProcessBusy = true;

        Logger().d('Streaming');

        final mat = TestOpenCv.convertImageToMat(image);

        List<cv.Point>? points;
        if (TfliteService.isLoaded) {
          points = TfliteService.detectDocument(mat);
        }
        points ??= TestOpenCv.processDocuments(mat);

        if (points != null && points.length == 4) {
          // Add to buffer for smoothing
          cornerBuffer.add(points);
          if (cornerBuffer.length > bufferSize) {
            cornerBuffer.removeAt(0);
          }

          // Calculate average corners
          corners = _getAverageCorners();
          _checkAutoCapture(corners!);
        } else {
          // If no detection, clear corners slowly or keep last good one
          if (cornerBuffer.isNotEmpty) {
            cornerBuffer.removeAt(0);
            if (cornerBuffer.isEmpty) {
              corners = null;
              autoCaptureProgress = 0.0;
              _stableSince = null;
            } else {
              corners = _getAverageCorners();
              _checkAutoCapture(corners!);
            }
          } else {
            corners = null;
            autoCaptureProgress = 0.0;
            _stableSince = null;
          }
        }

        isProcessBusy = false;
        if (!isClosed) update();
      });
    } catch (e) {
      Logger().i("Failed To do at Camera Controller because: $e");
    }
  }

  void _checkAutoCapture(List<cv.Point> currentCorners) {
    if (!isAutoCapture || isCapturing || isSavingDoc) {
      autoCaptureProgress = 0.0;
      _stableSince = null;
      return;
    }

    final now = DateTime.now();
    // Cooldown check (2.5 seconds after last auto-capture)
    if (_lastAutoCaptureTime != null &&
        now.difference(_lastAutoCaptureTime!).inMilliseconds < 2500) {
      autoCaptureProgress = 0.0;
      _stableSince = null;
      return;
    }

    // Check corner stability between frames
    if (_prevCorners != null && _prevCorners!.length == 4 && currentCorners.length == 4) {
      double maxShift = 0;
      for (int i = 0; i < 4; i++) {
        double dist = (currentCorners[i].x - _prevCorners![i].x).abs() +
            (currentCorners[i].y - _prevCorners![i].y).abs().toDouble();
        if (dist > maxShift) maxShift = dist;
      }

      // If shifted more than 35 pixels, the user is moving camera/document
      if (maxShift > 35) {
        _stableSince = now;
        autoCaptureProgress = 0.0;
      } else {
        _stableSince ??= now;
        final elapsedMs = now.difference(_stableSince!).inMilliseconds;
        const targetDurationMs = 1100; // ~1.1s of steady hold
        autoCaptureProgress = (elapsedMs / targetDurationMs).clamp(0.0, 1.0);

        if (autoCaptureProgress >= 1.0) {
          _lastAutoCaptureTime = now;
          _stableSince = null;
          autoCaptureProgress = 0.0;
          HapticFeedback.heavyImpact();
          captureAndProcess();
        }
      }
    } else {
      _stableSince = now;
      autoCaptureProgress = 0.0;
    }

    _prevCorners = currentCorners;
  }

  void updatePageNumber(int pageNumber) {
    currentCapturedPage = pageNumber;
    update();
  }

  void deleteAPage(int index, BuildContext context) {
    capturedImages.removeAt(index);
    if (capturedImages.isEmpty) {
      Navigator.pop(context);
    }
    update();
  }

  Future<void> saveFlushMood(FlashMode flashMod) async {
    try {
      flashMode = flashMod;
      update();

      await cameraController!.setFlashMode(flashMode);

      Box box = await HiveService.openBoxIfNeeded(hiveBoxName);

      switch (flashMode) {
        case .off:
          HiveService.put(box: box, key: flashMoodKey, value: FlashModel.off);

        case .torch:
          HiveService.put(box: box, key: flashMoodKey, value: FlashModel.torch);

        case .always:
          HiveService.put(
            box: box,
            key: flashMoodKey,
            value: FlashModel.always,
          );

        case .auto:
          HiveService.put(box: box, key: flashMoodKey, value: FlashModel.auto);
      }
    } catch (e) {
      Logger().i('failed to save flash mode because: $e');
    }
  }

  Future<FlashMode> getFlashMood() async {
    try {
      Box box = await HiveService.openBoxIfNeeded(hiveBoxName);

      final flashMode = HiveService.get(box: box, key: flashMoodKey);

      Logger().e('FlashMood: $flashMode');

      if (flashMode == null) {
        Logger().i('set auto flash mood FlashMood: $flashMode');
        return FlashMode.auto;
      }

      switch (flashMode) {
        case null:
          Logger().i("Flash mood is null so set auto");
          return FlashMode.auto;

        case FlashModel.off:
          return FlashMode.off;

        case FlashModel.auto:
          return FlashMode.auto;

        case FlashModel.always:
          return FlashMode.always;

        case FlashModel.torch:
          return FlashMode.torch;

        default:
          return FlashMode.auto;
      }
    } catch (e) {
      Logger().e(e);
      return FlashMode.auto;
    }
  }

  List<cv.Point> _getAverageCorners() {
    if (cornerBuffer.isEmpty) return [];
    List<cv.Point> avg = [
      cv.Point(0, 0),
      cv.Point(0, 0),
      cv.Point(0, 0),
      cv.Point(0, 0)
    ];

    for (var frame in cornerBuffer) {
      for (int i = 0; i < 4; i++) {
        avg[i] = cv.Point(avg[i].x + frame[i].x, avg[i].y + frame[i].y);
      }
    }

    return avg
        .map((p) => cv.Point(p.x ~/ cornerBuffer.length, p.y ~/ cornerBuffer.length))
        .toList();
  }

  Future<String?> captureAndProcess() async {
    if (isCapturing) return null;
    try {
      isCapturing = true;
      isFlashing = true; // Trigger flash animation
      update();

      // Take the picture
      XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // End flash after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        isFlashing = false;
        isSavingDoc = true; // Trigger "saving" animation
        update();
      });

      // Convert to Mat for processing
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

      // Use smoothed corners if available, else detect in high-res
      List<cv.Point>? finalCorners = corners;
      if (finalCorners == null || finalCorners.length != 4) {
        if (TfliteService.isLoaded) {
          finalCorners = TfliteService.detectDocument(mat);
        }
        finalCorners ??= TestOpenCv.processDocuments(mat);
      }

      if (finalCorners != null && finalCorners.length == 4) {
        // Warp and apply Magic Color
        final processedBytes = TestOpenCv.processAndWarp(mat, finalCorners);

        if (processedBytes != null) {
          // Save processed image
          final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = await ExportPath.saveImageToDir(
            processedBytes,
            fileName,
          );
          capturedImages.add(path);

          mat.dispose();

          // End saving animation after processing
          isSavingDoc = false;
          update();

          return path;
        }
      }

      // Fallback: if detection fails, save the original
      capturedImages.add(image.path);
      mat.dispose();
      isSavingDoc = false;
      return image.path;
    } catch (e) {
      Logger().e('Capture error: $e');
      isFlashing = false;
      isSavingDoc = false;
      return null;
    } finally {
      isCapturing = false;
      if (!isClosed) update();
    }
  }

  void addImagesForProcessedList(ProcessedImageModel image) {
    processedImageForTest.add(image);
    update();
  }

  Future<String?> generatePDF() async {
    if (capturedImages.isEmpty) return null;
    // PDF generation is temporarily disabled as DocumentProcessor was removed.
    return null;
  }

  @override
  void onInit() {
    initCamera();
    super.onInit();
  }

  @override
  void onClose() {
    if (cameraController != null && cameraController!.value.isStreamingImages) {
      cameraController!.stopImageStream();
    }
    cameraController?.dispose();
    super.onClose();
  }
}
