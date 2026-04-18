import 'package:doc_scanner/core/export_path/export_path.dart';

class DocScanner extends StatelessWidget {
  const DocScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightThemeData,
          darkTheme: AppTheme.darkThemeData,
          //TODO: implement dynamic theme mode;
          themeMode: ThemeMode.light,
          initialRoute: SplashView.name,
          onGenerateRoute: AppRoutes.routes,
          initialBinding: ControllerBinder(),
          // home: Test(),
        );
      },
    );
  }
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
