import 'package:doc_scanner/core/export_path/export_path.dart';


class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  static const name = 'custom camera screen';

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.high,
    );

    await controller!.initialize();
    setState(() {});
  }

  void switchCamera() async {
    selectedCameraIndex =
        selectedCameraIndex == 0 ? 1 : 0;

    controller = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.high,
    );

    await controller!.initialize();
    setState(() {});
  }

  Future<void> captureImage() async {
    final file = await controller!.takePicture();

    print("Image path: ${file.path}");
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          /// 📷 Camera Preview
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          /// 🔝 Top Controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                ),
              ],
            ),
          ),

          /// 🔽 Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                /// Capture Button
                GestureDetector(
                  onTap: captureImage,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Switch Camera Button
                IconButton(
                  onPressed: switchCamera,
                  icon: const Icon(Icons.cameraswitch,
                      color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}