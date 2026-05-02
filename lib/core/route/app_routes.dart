import 'package:doc_scanner/core/export_path/export_path.dart';

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
      final args = setting.arguments as String? ?? '';
      screenWidget = EditDocView(imagePath: args);
    } else if (setting.name == CustomCameraScreen.name) {
      screenWidget = CustomCameraScreen();
    } else if (setting.name == CapturedDocListView.name) {
      screenWidget = CapturedDocListView();
    }
    return MaterialPageRoute(builder: (context) => screenWidget);
  }
}
