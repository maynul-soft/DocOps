import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String searchHistroryKey = 'searchHistoryKey';

  static Future init() async {
    await Hive.initFlutter();
  }

  static Future<Box> openBoxIfNeeded(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    } else {
      return await Hive.openBox(boxName);
    }
  }

  static Future put({
    required Box box,
    required String key,
    required value,
  }) async {
    await box.put(key, jsonEncode(value));
  }

  static dynamic get({required Box box, required String key}) {
    var getData = box.get(key);
    final decodedData = jsonDecode(getData);
    return decodedData;
  }
}
