import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/model/flash_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  List<String> capturedImages = [];
  String hiveBoxName = 'customCameraController';
  String flashMoodKey = 'Flush Mood Key';
  FlashMode flashMode = FlashMode.auto;

  int currentCapturedPage = 0;

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();

      cameraController = CameraController(cameras.first, ResolutionPreset.high);

      FlashMode flashMod = await getFlashMood();
      flashMode = flashMod;

      await cameraController!.initialize();
      await cameraController!.setFlashMode(flashMod);

      update();
    } catch (e) {
      Logger().i("Failed To do at Camera Controller because: $e");
    }
  }

  Future<void> capture() async {
    XFile image = await cameraController!.takePicture();

    capturedImages.add(image.path);

    debugPrint('pats:======== $capturedImages');
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

      Logger().i('FlashMood: $flashMode');

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
