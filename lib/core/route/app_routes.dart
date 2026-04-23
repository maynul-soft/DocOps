import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/custom_camera_view.dart';

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
      screenWidget = EditDocView();
    } else if (setting.name == CustomCameraScreen.name) {
      screenWidget = CustomCameraScreen();
    }
    return MaterialPageRoute(builder: (context) => screenWidget);
  }
}
