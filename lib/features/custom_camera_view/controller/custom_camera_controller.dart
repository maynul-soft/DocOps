import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/controller/test_open_cv.dart';
import 'package:doc_scanner/features/custom_camera_view/model/flash_model.dart';
import 'package:doc_scanner/features/custom_camera_view/model/processed_image_model.dart';
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
  bool isCameraScreenOn = true;
  List<cv.Point>? corners;

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

        List<cv.Point>? points = TestOpenCv.processDocuments(mat);

        Logger().e(points.toString());

        corners = points;
        isProcessBusy = false;
        if (!isClosed) update();
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

  Future<String?> captureAndProcess() async {
    if (isCapturing) return null;
    try {
      isCapturing = true;
      update();

      // Take the picture
      XFile image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Convert to Mat for processing
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

      // Detect corners in the high-res image
      final detectedCorners = TestOpenCv.processDocuments(mat);

      if (detectedCorners != null && detectedCorners.length == 4) {
        // Warp and apply B&W
        final processedBytes = TestOpenCv.processAndWarp(mat, detectedCorners);

        if (processedBytes != null) {
          // Save processed image
          final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = await ExportPath.saveImageToDir(
            processedBytes,
            fileName,
          );
          capturedImages.add(path);

          mat.dispose();
          return path;
        }
      }

      // Fallback: if detection fails, save the original (or handle as error)
      capturedImages.add(image.path);
      mat.dispose();
      return image.path;
    } catch (e) {
      Logger().e('Capture error: $e');
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
