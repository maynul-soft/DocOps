import 'package:flutter/material.dart';

class CustomElevatedButtonTheme {
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: .circular(5),
      )
    )
  );

}