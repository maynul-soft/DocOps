import 'dart:io';

import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/custom_camera_view/model/change_flash_mood_button_model.dart';
import 'package:doc_scanner/features/custom_camera_view/widget/document_corner_painter.dart';
import 'package:doc_scanner/features/custom_camera_view/widget/scan_guide_overlay.dart';
import 'package:image_picker/image_picker.dart';

class CustomCameraScreen extends StatefulWidget {
  final String? targetDocId;
  const CustomCameraScreen({super.key, this.targetDocId});

  static const name = 'Custom camera view';

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  bool _initializedArgs = false;
  String? _targetDocId;

  @override
  void initState() {
    super.initState();
    Get.put(CustomCameraController(), permanent: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      final controller = Get.find<CustomCameraController>();
      controller.onLockedScanComplete = () {
        if (mounted) {
          _openReviewScreen(controller);
        }
      };

      if (args is Map) {
        if (args.containsKey('targetDocId')) {
          _targetDocId = args['targetDocId'] as String?;
        }
        if (args.containsKey('mode')) {
          controller.setScanMode(args['mode'] as CameraScanMode);
        }
        if (args['isLocked'] == true) {
          controller.isLockedMode = true;
        }
      } else if (args is String) {
        _targetDocId = args;
      }
    }
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

  void _openReviewScreen(CustomCameraController controller) {
    if (controller.capturedImages.isEmpty) return;
    final docId = widget.targetDocId ?? _targetDocId;
    Navigator.pushNamed(
      context,
      CapturedDocListView.name,
      arguments: docId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && Get.isRegistered<CustomCameraController>()) {
            Get.find<CustomCameraController>().capturedImages.clear();
          }
        },
        child: GetBuilder<CustomCameraController>(
          builder: (controller) {
            final cam = controller.cameraController;

            if (cam == null || !cam.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return Container(
              height: double.maxFinite,
              width: double.maxFinite,
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                children: [
                  Gap.height(50),
                  buildAppBarSection(controller, context),
                  const SizedBox(height: 8),
                  Expanded(
                    child: buildCameraViewSection(context, cam, controller),
                  ),
                  const SizedBox(height: 10),
                  buildModeSelector(controller),
                  const SizedBox(height: 6),
                  buildBottomViewSection(controller, context),
                  const SizedBox(height: 12),
                ],
              ),
            );
        },
      ),
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
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickMultiImage();
                if (picked.isNotEmpty) {
                  controller.capturedImages.addAll(picked.map((e) => e.path));
                  controller.update();
                }
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (controller.isAutoCapture && controller.autoCaptureProgress > 0)
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: CircularProgressIndicator(
                        value: controller.autoCaptureProgress,
                        strokeWidth: 4,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2.5,
                        color: controller.isAutoCapture && controller.autoCaptureProgress > 0
                            ? const Color(0xFF10B981)
                            : Colors.white,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: controller.isAutoCapture
                          ? const Color(0xFF2563EB)
                          : Colors.white,
                      radius: 28,
                      child: controller.isAutoCapture
                          ? const Icon(Icons.auto_awesome, color: Colors.white, size: 24)
                          : const Icon(Icons.camera_alt, color: Colors.black87, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: buildCustomButton(
              onTap: () {
                if (controller.capturedImages.isNotEmpty) {
                  _openReviewScreen(controller);
                }
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

  Widget buildModeSelector(CustomCameraController controller) {
    if (controller.isLockedMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              controller.scanMode == CameraScanMode.idCard
                  ? Icons.badge_outlined
                  : Icons.menu_book_outlined,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              controller.scanMode == CameraScanMode.idCard
                  ? (controller.idCardStep == 1
                      ? '🪪 ID Card: Step 1 (Front)'
                      : '🪪 ID Card: Step 2 (Back)')
                  : '📖 Passport Scan Mode',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // In normal scan mode, ID Card and Passport options are NOT displayed
    // as they are accessible via dedicated quick actions from the Home screen.
    return const SizedBox.shrink();
  }


  Widget buildCameraViewSection(
    BuildContext context,
    CameraController cam,
    CustomCameraController controller,
  ) {
    // final screenSize = Size(
    //   MediaQuery.of(context).size.width,
    //   MediaQuery.of(context).size.height * 0.750,
    // );

    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Stack(
        children: [
          Positioned.fill(child: CameraPreview(cam)),
          // Flash Effect
          if (controller.isFlashing)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),
          // Document Saving Animation
          if (controller.isSavingDoc)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    controller.scanMode == CameraScanMode.idCard
                        ? (controller.idCardStep == 2 ? 'Stitching ID Card...' : 'Saving Front...')
                        : 'Enhancing...',
                    style: CustomTextTheme.fontSize14(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          // ID Card & Passport Alignment Guideline Overlay
          ScanGuideOverlay(
            mode: controller.scanMode,
            idCardStep: controller.idCardStep,
            isDetected: controller.corners != null,
          ),
          if (controller.scanMode == CameraScanMode.document &&
              controller.corners != null &&
              controller.imageSize != null) ...[
            Positioned.fill(
              child: CustomPaint(
                painter: DocumentCornerPainter(
                  points: controller.corners!,
                  previewSize: controller.imageSize!,
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.isAutoCapture && controller.autoCaptureProgress > 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.95)
                        : const Color(0xFF1D4ED8).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: controller.isAutoCapture && controller.autoCaptureProgress > 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: controller.isAutoCapture && controller.autoCaptureProgress > 0 ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isAutoCapture && controller.autoCaptureProgress > 0) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hold steady... ${(controller.autoCaptureProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          controller.isAutoCapture ? Icons.auto_awesome : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isAutoCapture
                              ? 'Document Detected — Hold Steady'
                              : 'Document Detected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          controller.capturedImages.isNotEmpty
              ? Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      _openReviewScreen(controller);
                    },
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * -100),
                          child: Transform.scale(
                            scale: 0.5 + (0.5 * value),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Image.file(
                        height: 50,
                        width: 50,
                        fit: BoxFit.fill,
                        File(controller.capturedImages.last), // Use last captured
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),

          controller.capturedImages.isNotEmpty
              ? Positioned(
                  bottom: 45,
                  right: 0,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildCustomButton(
            onTap: () {
              controller.capturedImages.clear();
              Navigator.pop(context);
            },
            child: const Icon(Icons.close, size: 28, color: Colors.white),
          ),
          // Auto / Manual Mode Toggle Pill
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => controller.toggleAutoCapture(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: controller.isAutoCapture
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: controller.isAutoCapture ? Colors.white : Colors.white60,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto',
                          style: TextStyle(
                            color: controller.isAutoCapture ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => controller.toggleAutoCapture(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !controller.isAutoCapture
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: !controller.isAutoCapture ? Colors.white : Colors.white60,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manual',
                          style: TextStyle(
                            color: !controller.isAutoCapture ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                      if (!context.mounted) return;
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
