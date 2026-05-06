import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/edit_doc/controller/edit_doc_controller.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.put(ScanNewDocController());
    Get.put(EditDocController());

  }
}
