import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_paint_practice/practice.dart';

class AppRoutes {
  static Route<dynamic> routes(RouteSettings setting) {
    late final Widget screenWidget;
    if (setting.name == SplashView.name) {
      screenWidget = SplashView();
    } else if (setting.name == HomeView.name) {
      screenWidget = HomeView();
    } else if (setting.name == DocDetailVew.name) {
      screenWidget = DocDetailVew();
    } else if (setting.name == EditDocView.name) {
      String? args = setting.arguments != null
          ? setting.arguments as String?
          : null;
      screenWidget = EditDocView(imagePath: args);
    } else if (setting.name == CustomCameraScreen.name) {
      screenWidget = CustomCameraScreen();
    } else if (setting.name == CapturedDocListView.name) {
      screenWidget = CapturedDocListView();
    } else if (setting.name == Practice.name) {
      screenWidget = Practice();
    }
    return MaterialPageRoute(builder: (context) => screenWidget);
  }
}
