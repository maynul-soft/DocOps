import 'package:doc_scanner/core/export_path/export_path.dart';

class AppRoutes {
  static Route<dynamic> routes(RouteSettings setting) {
    late final Widget screenWidget;

    if (setting.name == SplashView.name) {
      screenWidget = SplashView();
    } else if (setting.name == HomeView.name) {
      screenWidget = HomeView();
    }
    return MaterialPageRoute(builder: (context) => screenWidget);
  }
}
