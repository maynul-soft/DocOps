
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/core/services/tflite/tflite_service.dart';


class InitServices {
  static Future initAll() async {
    await HiveService.init();
    await TfliteService.init();
  }
}
