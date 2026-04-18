import 'package:doc_scanner/core/export_path/export_path.dart';

class CustomTextTheme {
  static TextTheme customTextTheme = TextTheme(
    // 36 Manrope (Standard/Regular)
    displayLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 36,
      fontWeight: FontWeight.normal,
    ),

    // 20 Bold Manrope
    headlineLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),

    // 20 Manrope (Regular)
    headlineMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 20,
      fontWeight: FontWeight.normal,
    ),

    // 18 Bold Manrope
    titleLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),

    // 18 Inter
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.normal,
    ),

    // 14 Inter
    bodyLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),

    // 12 Inter
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),

    // 11 Inter
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.normal,
    ),

    // 10 Inter
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 10,
      fontWeight: FontWeight.normal,
    ),

    // 9 Inter
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 9,
      fontWeight: FontWeight.normal,
    ),
  );

  static TextStyle fontSize36(BuildContext context) {
    return TextTheme.of(context).displayLarge!;
  }

  static TextStyle fontSize20bold(BuildContext context) {
    return TextTheme.of(context).headlineLarge!;
  }

  static TextStyle fontSize20regular(BuildContext context) {
    return TextTheme.of(context).headlineMedium!;
  }

  static TextStyle fontSize18bold(BuildContext context) {
    return TextTheme.of(context).titleLarge!;
  }

  static TextStyle fontSize18regular(BuildContext context) {
    return TextTheme.of(context).titleMedium!;
  }

  static TextStyle fontSize14(BuildContext context) {
    return TextTheme.of(context).bodyLarge!;
  }

  static TextStyle fontSize12(BuildContext context) {
    return TextTheme.of(context).bodyMedium!;
  }

  static TextStyle fontSize11(BuildContext context) {
    return TextTheme.of(context).bodySmall!;
  }

  static TextStyle fontSize10(BuildContext context) {
    return TextTheme.of(context).labelLarge!;
  }

  static TextStyle fontSize9(BuildContext context) {
    return TextTheme.of(context).labelSmall!;
  }
}
