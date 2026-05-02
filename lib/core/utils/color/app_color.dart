import 'package:flutter/material.dart';

class AppColors {
  static const Color _appColor = Color(0xff0082E0);
  // static const Color _scaffodColor = Color.fromARGB(239, 246, 246, 246);
  // static const Color _purpleColor = Color.fromARGB(255, 219, 221, 250);
  // static const Color _lightPink = Color(0xffFFDADE);
  // static const Color _fieryRose = Color(0xffFF4858);
  // static const Color _greenAccent = Color.fromARGB(215, 181, 221, 156);

  static final themeColor = getMaterialColor(_appColor);
  // static final bottomNavColor = Colors.white;

  // static get scaffoldColor => _scaffodColor;
  // static get purpleColor => _purpleColor;
  // static get lightPink => _lightPink;
  // static get fieryRose => _fieryRose;
  // static get greenAccent => _greenAccent;

  static MaterialColor getMaterialColor(Color color) {
    int red = (color.r * 255.0).round().clamp(0, 255);
    int green = (color.g * 255.0).round().clamp(0, 255);
    int blue = (color.b * 255.0).round().clamp(0, 255);

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.toARGB32(), shades);
  }
}
