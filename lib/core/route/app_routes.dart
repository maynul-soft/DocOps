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
      final targetDocId = setting.arguments is String ? setting.arguments as String : null;
      screenWidget = CustomCameraScreen(targetDocId: targetDocId);
    } else if (setting.name == CapturedDocListView.name) {
      final targetDocId = setting.arguments is String ? setting.arguments as String : null;
      screenWidget = CapturedDocListView(targetDocId: targetDocId);
    } else if (setting.name == Practice.name) {
      screenWidget = Practice();
    }
    return MaterialPageRoute(
      builder: (context) => screenWidget,
      settings: setting,
    );
  }
}
