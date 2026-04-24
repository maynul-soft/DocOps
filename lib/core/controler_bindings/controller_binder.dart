import 'package:doc_scanner/core/export_path/export_path.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.put(ScanNewDocController());
    Get.put(CustomCameraController());
  }
}
