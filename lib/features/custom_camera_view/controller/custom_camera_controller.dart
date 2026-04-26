import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/model/flash_model.dart';
import 'package:flutter/foundation.dart';



class CustomCameraController extends GetxController {
  CameraController? cameraController;
  List<String> capturedImages = [];
  String hiveBoxName = 'customCameraController';
  String flashMoodKey = 'Flush Mood Key';
  FlashMode flashMode = FlashMode.auto;
  bool isProcessBusy = false;
  ObjectDetector? objectDetector;
  Size? imageSize;
  bool isCapturing = false;
  List<DetectedObject> object = [];

  int currentCapturedPage = 0;

  Future<void> initCamera() async {
    try {
      objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.stream,
          classifyObjects: true,
          multipleObjects: false,
        ),
      );

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

        processImage(image);
      });
    } catch (e) {
      Logger().i("Failed To do at Camera Controller because: $e");
    }
  }

  Future<void> capture() async {
    if(isCapturing) return;
    isCapturing = true;

    XFile image = await cameraController!.takePicture();

    capturedImages.add(image.path);

    debugPrint('pats:======== $capturedImages');
    isCapturing = false;
    update();
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

      imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final WriteBuffer  allBytes = WriteBuffer();

      for(final plane in image.planes){
        allBytes.putUint8List(plane.bytes);
      }

      final bytes = allBytes.done().buffer.asUint8List();
       

      InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final detectedObject = await objectDetector!.processImage(inputImage);

      object = detectedObject;
      Logger().f(detectedObject.toString());
      isProcessBusy = false;
      update();
    } catch (e) {
      Logger().i(e.toString());
    }
  }

  @override
  void onInit() {
    initCamera();
    super.onInit();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    objectDetector!.close();
    super.onClose();
  }
}
