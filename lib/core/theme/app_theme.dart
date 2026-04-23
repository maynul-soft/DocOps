import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/core/theme/custom_elevated_button_theme.dart';

class AppTheme {
  static ThemeData lightThemeData = ThemeData(
    useMaterial3: true,
    textTheme: CustomTextTheme.customTextTheme,
    elevatedButtonTheme: CustomElevatedButtonTheme.elevatedButtonTheme,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: Color(0xff005DA7),
    ),
  );

  static ThemeData darkThemeData = ThemeData(
    useMaterial3: true,
    textTheme: CustomTextTheme.customTextTheme,
    elevatedButtonTheme: CustomElevatedButtonTheme.elevatedButtonTheme,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: Color(0xff005DA7),
    ),
  );
}
