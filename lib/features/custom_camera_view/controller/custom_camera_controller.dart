import 'package:flutter/services.dart';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/controller/test_open_cv.dart';
import 'package:doc_scanner/features/custom_camera_view/model/flash_model.dart';
import 'package:doc_scanner/features/custom_camera_view/model/processed_image_model.dart';
import 'package:doc_scanner/features/custom_camera_view/widget/scan_guide_overlay.dart';
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

  // Scan Modes: Document, ID Card, Passport
  CameraScanMode scanMode = CameraScanMode.document;
  int idCardStep = 1; // 1 = Front, 2 = Back
  String? idCardFrontPath;
  bool isLockedMode = false;
  VoidCallback? onLockedScanComplete;

  void setScanMode(CameraScanMode mode) {
    scanMode = mode;
    idCardStep = 1;
    idCardFrontPath = null;
    update();
  }

  void resetIdCardScan() {
    idCardStep = 1;
    idCardFrontPath = null;
    update();
  }

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

  DateTime? _lastStreamProcessTime;

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

        // Throttle to at most 10 fps to prevent native heap exhaustion and CPU overload
        final now = DateTime.now();
        if (_lastStreamProcessTime != null &&
            now.difference(_lastStreamProcessTime!).inMilliseconds < 100) {
          return;
        }
        _lastStreamProcessTime = now;

        // Note: the Mat is rotated 90 degrees in TestOpenCv, so swap width and height
        imageSize = Size(image.height.toDouble(), image.width.toDouble());

        isProcessBusy = true;

        cv.Mat? mat;
        List<cv.Point>? points;
        try {
          mat = TestOpenCv.convertImageToMat(image);
          if (TfliteService.isLoaded) {
            points = TfliteService.detectDocument(mat);
          }
          points ??= TestOpenCv.processDocuments(mat);
        } catch (e) {
          // Ignore transient camera frame errors
        } finally {
          mat?.dispose();
        }

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

      // If in ID Card or Passport mode and no corners were reliably detected,
      // fallback to the exact landscape frame matching the on-screen guide
      if (finalCorners == null || finalCorners.length != 4) {
        if (scanMode == CameraScanMode.idCard) {
          // Standard ID-1 1.586 : 1 landscape card box
          final cropW = (mat.width * 0.90).toInt();
          final cropH = (cropW / 1.586).toInt();
          final cropX = ((mat.width - cropW) / 2).toInt();
          final cropY = ((mat.height - cropH) / 2).toInt();
          finalCorners = [
            cv.Point(cropX, cropY),
            cv.Point(cropX + cropW, cropY),
            cv.Point(cropX + cropW, cropY + cropH),
            cv.Point(cropX, cropY + cropH),
          ];
        } else if (scanMode == CameraScanMode.passport) {
          // Standard ID-3 1.42 : 1 landscape passport box
          final cropW = (mat.width * 0.92).toInt();
          final cropH = (cropW / 1.42).toInt();
          final cropX = ((mat.width - cropW) / 2).toInt();
          final cropY = ((mat.height - cropH) / 2).toInt();
          finalCorners = [
            cv.Point(cropX, cropY),
            cv.Point(cropX + cropW, cropY),
            cv.Point(cropX + cropW, cropY + cropH),
            cv.Point(cropX, cropY + cropH),
          ];
        }
      }

      String resultPath = image.path;
      if (finalCorners != null && finalCorners.length == 4) {
        // Warp and apply Magic Color
        final processedBytes = TestOpenCv.processAndWarp(mat, finalCorners);
        if (processedBytes != null) {
          final prefix = scanMode == CameraScanMode.idCard
              ? 'id'
              : (scanMode == CameraScanMode.passport ? 'passport' : 'doc');
          final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          resultPath = await ExportPath.saveImageToDir(
            processedBytes,
            fileName,
          );
        }
      }

      mat.dispose();

      // Handle ID Card dual-side scan flow
      if (scanMode == CameraScanMode.idCard) {
        if (idCardStep == 1) {
          idCardFrontPath = resultPath;
          idCardStep = 2;
          isSavingDoc = false;
          Get.snackbar(
            'Front Side Saved',
            'Now flip your card and scan the Back Side',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1E293B),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          update();
          return resultPath;
        } else {
          // Step 2: Save both Front and Back so user can edit and rotate each side individually
          final frontPath = idCardFrontPath!;
          final backPath = resultPath;
          idCardStep = 1;
          idCardFrontPath = null;
          isSavingDoc = false;

          capturedImages.add(frontPath);
          capturedImages.add(backPath);
          update();

          if (isLockedMode) {
            // Auto complete and navigate to review
            onLockedScanComplete?.call();
          } else {
            Get.snackbar(
              'ID Card Scanned',
              'Both sides captured. You can edit and rotate each side.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF10B981),
              colorText: Colors.white,
            );
          }
          return backPath;
        }
      } else if (scanMode == CameraScanMode.passport) {
        // Passport mode: single page capture
        capturedImages.add(resultPath);
        isSavingDoc = false;
        update();

        if (isLockedMode) {
          // Auto complete and navigate to review
          onLockedScanComplete?.call();
        }
        return resultPath;
      } else {
        // Standard document mode
        capturedImages.add(resultPath);
        isSavingDoc = false;
        update();
        return resultPath;
      }
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
