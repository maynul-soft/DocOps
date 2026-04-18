
import 'package:doc_scanner/core/export_path/export_path.dart';


class InitServices {
  static Future initAll() async {
    await HiveService.init();
  }
}
