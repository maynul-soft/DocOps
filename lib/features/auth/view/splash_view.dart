import 'package:doc_scanner/core/export_path/export_path.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  static const name = 'splash view';

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Future<void> goToNextScreen() async {
    await Future.delayed(Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushNamed(context, HomeView.name);
    // Navigator.pushNamed(context, TestFromImageView.name);
  }

  @override
  void initState() {
    super.initState();
    goToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme appColors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(),
        child: Stack(
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).primaryColor.withAlpha(70),
                    ),
                    child: SvgPicture.asset(
                      IconsPath.logoSvg,
                      height: 100,
                      width: 100,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Gap.height(10),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: Text(
                      'DocOps',
                      style: CustomTextTheme.fontSize36(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Text(
                    'Scan Your Operations',
                    style: CustomTextTheme.fontSize12(
                      context,
                    ).copyWith(color: appColors.primary),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: .end,
              children: [
                Row(
                  mainAxisAlignment: .center,
                  children: [
                    Text(
                      textAlign: .center,
                      'Dev and supported by Maynul Think\nversion 1.0.0',
                      style: CustomTextTheme.fontSize12(
                        context,
                      ).copyWith(letterSpacing: 1, color: appColors.primary),
                    ),
                  ],
                ),
                Gap.height(20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
