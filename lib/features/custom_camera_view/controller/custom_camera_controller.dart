import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/model/flash_model.dart';
import 'package:doc_scanner/features/custom_camera_view/service/document_processor.dart';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  List<String> capturedImages = [];
  String hiveBoxName = 'customCameraController';
  String flashMoodKey = 'Flush Mood Key';
  FlashMode flashMode = FlashMode.auto;
  bool isProcessBusy = false;
  Size? imageSize;
  bool isCapturing = false;
  DocumentCorners? detectedCorners;

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
        if (isProcessBusy) return;
        isProcessBusy = true;

        Logger().d("Streaming");

        processImage(image);
      });
    } catch (e) {
      Logger().i("Failed To do at Camera Controller because: $e");
    }
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

  void processImage(CameraImage image) async {
    try {
      Logger().d('Image processing started');

      final mat = _convertCameraImageToMat(image);
      if (mat == null) {
        isProcessBusy = false;
        Logger().e("Failed to get mat");
        return;
      }

      imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final corners = await DocumentProcessor.detectDocumentCorners(mat);
      detectedCorners = corners;

      Logger().e(
        'Corners: ${detectedCorners != null ? "পাওয়া গেছে ✅" : "পাওয়া যায়নি ❌"}',
      );
      Logger().e('ImageSize: $imageSize');
      isProcessBusy = false;
      update();
    } catch (e) {
      Logger().i(e.toString());
    }
  }

  cv.Mat? _convertCameraImageToMat(CameraImage image) {
    try {
      Logger().e('CV mat doing');

      if (image.format.group == ImageFormatGroup.yuv420) {
        final int width = image.width;
        final int height = image.height;

        // ✅ imageSize এখানে সেট করো — portrait হলে swap করো
        imageSize = Size(height.toDouble(), width.toDouble()); // ✅ swap

        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];

        final nv21 = Uint8List(width * height * 3 ~/ 2);

        for (int i = 0; i < height; i++) {
          nv21.setRange(
            i * width,
            (i + 1) * width,
            yPlane.bytes,
            i * yPlane.bytesPerRow,
          );
        }

        int uvIndex = width * height;
        for (int i = 0; i < height ~/ 2; i++) {
          for (int j = 0; j < width ~/ 2; j++) {
            nv21[uvIndex++] = vPlane.bytes[i * vPlane.bytesPerRow + j];
            nv21[uvIndex++] = uPlane.bytes[i * uPlane.bytesPerRow + j];
          }
        }

        final yuvMat = cv.Mat.fromList(
          height + height ~/ 2,
          width,
          cv.MatType.CV_8UC1,
          nv21,
        );

        // ✅ YUV → BGR
        final bgrMat = cv.cvtColor(yuvMat, cv.COLOR_YUV2BGR_NV21);

        // ✅ Portrait এ rotate করো
        final rotatedMat = cv.rotate(bgrMat, cv.ROTATE_90_CLOCKWISE);

        yuvMat.dispose();
        bgrMat.dispose();

        return rotatedMat;
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // iOS
        imageSize = Size(image.width.toDouble(), image.height.toDouble());
        final bytes = image.planes[0].bytes;
        final mat = cv.Mat.fromList(
          image.height,
          image.width,
          cv.MatType.CV_8UC4,
          bytes,
        );
        final bgrMat = cv.cvtColor(mat, cv.COLOR_BGRA2BGR);
        mat.dispose();
        return bgrMat;
      }
      return null;
    } catch (e) {
      Logger().e('Convert error: $e');
      return null;
    }
  }

  Future<String?> captureAndProcess() async {
    if (isCapturing) return null;
    try {
      isCapturing = true;
      update();

      await cameraController!.stopImageStream();
      XFile image = await cameraController!.takePicture();

      String? processedPath;

      if (detectedCorners != null) {
        // ✅ Crop + Perspective transform
        processedPath = await DocumentProcessor.processDocument(
          imagePath: image.path,
          corners: detectedCorners!,
          applyBW: true,
        );
      }

      capturedImages.add(processedPath ?? image.path);

      await cameraController!.startImageStream((img) {
        if (isProcessBusy) return;
        isProcessBusy = true;
        processImage(img);
      });

      return processedPath;
    } catch (e) {
      Logger().e('Capture error: $e');
      return null;
    } finally {
      isCapturing = false;
      update();
    }
  }

  Future<String?> generatePDF() async {
    if (capturedImages.isEmpty) return null;
    return await DocumentProcessor.createPDF(capturedImages);
  }

  @override
  void onInit() {
    initCamera();
    super.onInit();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
