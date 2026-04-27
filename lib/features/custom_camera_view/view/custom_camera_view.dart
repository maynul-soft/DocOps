import 'dart:io';

import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/model/change_flash_mood_button_model.dart';
import 'package:doc_scanner/features/custom_camera_view/widget/document_corner_painter.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  static const name = 'Custom camera view';

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(CustomCameraController(), permanent: false);
    
  }

  @override
  void dispose() {
    Get.delete<CustomCameraController>();
    super.dispose();
  }

  final List<ChangeFlashMoodButtonModel> flashIcons = [
    ChangeFlashMoodButtonModel(
      icon: Icons.flash_on,
      flashMode: FlashMode.always,
    ),
    ChangeFlashMoodButtonModel(
      icon: Icons.flash_auto,
      flashMode: FlashMode.auto,
    ),
    ChangeFlashMoodButtonModel(
      icon: Icons.flashlight_on,
      flashMode: FlashMode.torch,
    ),
    ChangeFlashMoodButtonModel(icon: Icons.flash_off, flashMode: FlashMode.off),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GetBuilder<CustomCameraController>(
        builder: (controller) {
          final cam = controller.cameraController;

          if (cam == null || !cam.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Container(
            height: double.maxFinite,
            width: double.maxFinite,
            decoration: BoxDecoration(color: Colors.black),
            child: Column(
              children: [
                Gap.height(50),
                buildAppBarSection(controller, context),
                Gap.height(10),
                buildCameraViewSection(context, cam, controller),
                Gap.height(20),
                buildBottomViewSection(controller, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding buildBottomViewSection(
    CustomCameraController controller,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: .center,
        mainAxisAlignment: .center,
        children: [
          Expanded(
            flex: 1,
            child: buildCustomButton(
              onTap: () {
                //TODO: implement with this logic

                // controller.capturedImages.isEmpty
              },
              child: Column(
                children: [
                  Icon(
                    Icons.image,
                    color: controller.capturedImages.isEmpty
                        ? Colors.blue
                        : Colors.grey,
                    size: 30,
                  ),
                  Text(
                    'Import',
                    style: CustomTextTheme.fontSize12(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: buildCustomButton(
              onTap: () {
                controller.captureAndProcess();
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: Colors.white),
                ),
                child: CircleAvatar(backgroundColor: Colors.blue, radius: 30),
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: buildCustomButton(
              onTap: () {
                controller.capturedImages.isNotEmpty
                    ? Get.toNamed(CapturedDocListView.name)
                    : null;
              },
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: controller.capturedImages.isNotEmpty
                            ? ColorScheme.of(context).primary
                            : Colors.grey,
                      ),
                      color: controller.capturedImages.isNotEmpty
                          ? ColorScheme.of(context).primary.withAlpha(100)
                          : Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Complete',
                      style: CustomTextTheme.fontSize12(context).copyWith(
                        color: controller.capturedImages.isNotEmpty
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCameraViewSection(
    BuildContext context,
    CameraController cam,
    CustomCameraController controller,
  ) {
    final screenSize = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height * 0.750,
    );

    return SizedBox(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * 0.750,
      child: Stack(
        children: [
          Positioned.fill(child: CameraPreview(cam)),
          if (controller.detectedCorners != null &&
              controller.imageSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: DocumentCornerPainter(
                  corners: controller.detectedCorners!,
                  imageSize: controller.imageSize!,
                  screenSize: screenSize,
                ),
              ),
            ),
          controller.capturedImages.isNotEmpty
              ? Positioned(
                  bottom: 10,
                  right: 10,
                  child: Image.file(
                    height: 50,
                    width: 50,
                    fit: BoxFit.fill,
                    File(controller.capturedImages.first),
                  ),
                )
              : SizedBox.shrink(),

          controller.capturedImages.isNotEmpty
              ? Positioned(
                  bottom: 45,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(CapturedDocListView.name);
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 1, color: Colors.white),
                        color: Colors.red,
                      ),

                      child: Text(
                        controller.capturedImages.length.toString(),
                        style: CustomTextTheme.fontSize12(
                          context,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Padding buildAppBarSection(
    CustomCameraController controller,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          buildCustomButton(
            onTap: () {
              Get.delete<CustomCameraController>();
              Get.back();
            },
            child: Icon(Icons.close, size: 30, color: Colors.blue),
          ),
          buildCustomButton(
            onTap: () {
              onTapToChangeFlashMode(context, controller);
            },
            child: setFlashIcon(controller.flashMode),
          ),
        ],
      ),
    );
  }

  void onTapToChangeFlashMode(
    BuildContext context,
    CustomCameraController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return GetBuilder<CustomCameraController>(
          builder: (controller) {
            return AlertDialog(
              content: Row(
                mainAxisAlignment: .spaceAround,
                children: flashIcons.asMap().entries.map((item) {
                  return GestureDetector(
                    onTap: () async {
                      await controller.saveFlushMood(item.value.flashMode);
                      Navigator.pop(context);
                    },
                    child: Icon(
                      item.value.icon,
                      color: item.value.flashMode == controller.flashMode
                          ? Colors.blue
                          : null,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget setFlashIcon(FlashMode flashMode) {
    if (flashMode == FlashMode.auto) {
      return Icon(Icons.flash_auto, color: Colors.blue);
    } else if (flashMode == FlashMode.always) {
      return Icon(Icons.flash_on, color: Colors.blue);
    } else if (flashMode == FlashMode.off) {
      return Icon(Icons.flash_off, color: Colors.blue);
    } else if (flashMode == FlashMode.torch) {
      return Icon(Icons.flashlight_on_sharp, color: Colors.blue);
    } else {
      return Icon(Icons.flash_on);
    }
  }

  Widget buildCustomButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(onTap: onTap, child: child);
  }
}
