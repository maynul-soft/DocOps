import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class Ios {
  static const MethodChannel _channel = MethodChannel(
    'com.example.cenith_storage/LocationSetting',
  );

  static Future<void> openIosLocationSettings() async {
    try {
      await _channel.invokeMethod('openIosLocationSetting');
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
  }
}
