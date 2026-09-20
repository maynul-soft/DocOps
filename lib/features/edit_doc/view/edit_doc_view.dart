import 'dart:ui' as ui;
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/edit_doc/controller/edit_doc_controller.dart';
import 'package:doc_scanner/features/edit_doc/model/draw_model.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class EditDocView extends StatefulWidget {
  final String? imagePath;
  const EditDocView({super.key, this.imagePath});

  static const name = 'EditDocView';

  @override
  State<EditDocView> createState() => _EditDocViewState();
}

class _EditDocViewState extends State<EditDocView> {
  ui.Image? image;
  String? _currentPath;
  Size _canvasSize = Size.zero;

  // Crop State
  List<Offset> cropPoints = []; // 4 points: TL, TR, BR, BL in screen coordinates
  int? activeCropIndex;
  Rect? imageDisplayRect;
  bool isProcessingCrop = false;

  String? get activeImagePath =>
      _currentPath ?? widget.imagePath ?? (ModalRoute.of(context)?.settings.arguments as String?);

  void loadImage() async {
    final path = activeImagePath;
    if (path == null) return;
    _currentPath = path;

    final loadedImage = await Get.find<EditDocController>().convertImage(path);
    if (mounted) {
      setState(() {
        image = loadedImage;
        cropPoints.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadImage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentPath == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _currentPath = args;
        loadImage();
      }
    }
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  Rect _calculateImageRect(Size containerSize) {
    if (image == null || containerSize == Size.zero) return Rect.zero;
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(image!.width.toDouble(), image!.height.toDouble()),
      containerSize,
    );
    return Alignment.center.inscribe(fitted.destination, Offset.zero & containerSize);
  }

  void _initDefaultCropPoints() {
    if (imageDisplayRect == null || imageDisplayRect == Rect.zero) return;
    final rect = imageDisplayRect!;
    final dx = rect.width * 0.05;
    final dy = rect.height * 0.05;
    cropPoints = [
      Offset(rect.left + dx, rect.top + dy), // TL
      Offset(rect.right - dx, rect.top + dy), // TR
      Offset(rect.right - dx, rect.bottom - dy), // BR
      Offset(rect.left + dx, rect.bottom - dy), // BL
    ];
  }

  void _onEnterCropMode(EditDocController controller) {
    controller.toggleCropMode();
    if (controller.isCropping) {
      _initDefaultCropPoints();
      setState(() {});
    }
  }

  void _onAutoDetectCrop(EditDocController controller) async {
    final path = activeImagePath;
    if (path == null || image == null || imageDisplayRect == null) return;

    setState(() => isProcessingCrop = true);
    final detected = await controller.detectDocumentCorners(path);
    setState(() => isProcessingCrop = false);

    if (detected != null && detected.length == 4) {
      final rect = imageDisplayRect!;
      cropPoints = detected.map((pt) {
        final sx = rect.left + (pt.x / image!.width) * rect.width;
        final sy = rect.top + (pt.y / image!.height) * rect.height;
        return Offset(
          sx.clamp(rect.left, rect.right),
          sy.clamp(rect.top, rect.bottom),
        );
      }).toList();
      setState(() {});
    } else {
      Get.snackbar('Auto-Detect', 'No clear document border found, using default frame');
      _initDefaultCropPoints();
      setState(() {});
    }
  }

  void _onResetCrop() {
    if (imageDisplayRect == null) return;
    final rect = imageDisplayRect!;
    cropPoints = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    setState(() {});
  }

  void _onApplyCrop(EditDocController controller) async {
    final path = activeImagePath;
    if (path == null || image == null || imageDisplayRect == null || cropPoints.length != 4) {
      controller.isCropping = false;
      controller.update();
      return;
    }

    setState(() => isProcessingCrop = true);

    final rect = imageDisplayRect!;
    final cvPoints = cropPoints.map((pt) {
      final ix = ((pt.dx - rect.left) / rect.width * image!.width).clamp(0, image!.width).toInt();
      final iy = ((pt.dy - rect.top) / rect.height * image!.height).clamp(0, image!.height).toInt();
      return cv.Point(ix, iy);
    }).toList();

    final success = await controller.cropAndWarpImage(
      imagePath: path,
      points: cvPoints,
    );

    setState(() => isProcessingCrop = false);

    if (success) {
      controller.isCropping = false;
      controller.update();
      loadImage();
      Get.snackbar('Success', 'Document cropped and straightened');
    } else {
      Get.snackbar('Error', 'Failed to crop image');
    }
  }

  void _onTapDone(EditDocController controller) async {
    final path = activeImagePath;
    if (path == null) {
      Get.back();
      return;
    }

    // If in crop mode, apply crop first
    if (controller.isCropping) {
      _onApplyCrop(controller);
      return;
    }

    // If user drew lines, save the composite
    if (controller.pointList.isNotEmpty && _canvasSize.width > 0) {
      final success = await controller.saveEditedImage(
        imagePath: path,
        width: _canvasSize.width.toInt(),
        height: _canvasSize.height.toInt(),
      );
      if (success) {
        controller.pointList.clear();
        controller.reDoPoints.clear();
        Get.back(result: true);
        return;
      }
    }

    Get.back(result: true);
  }

  void _onTapRotate(EditDocController controller) async {
    final path = activeImagePath;
    if (path == null) return;
    await controller.rotateImage(path);
    loadImage();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: buildAppSection(colorScheme),
      body: GetBuilder<EditDocController>(
        builder: (editDocController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: size.height - 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) {
                              if (editDocController.isCropping) {
                                _handleCropPanStart(details.localPosition);
                              } else if (editDocController.isDrawing) {
                                editDocController.addStartOffset(details.localPosition);
                              }
                            },
                            onPanUpdate: (details) {
                              if (editDocController.isCropping) {
                                _handleCropPanUpdate(details.localPosition);
                              } else if (editDocController.isDrawing) {
                                editDocController.addOffset(details.localPosition);
                              }
                            },
                            onPanEnd: (details) {
                              if (editDocController.isCropping) {
                                activeCropIndex = null;
                                setState(() {});
                              } else if (editDocController.isDrawing) {
                                editDocController.addOffset(details.localPosition);
                              }
                            },
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constrains) {
                                _canvasSize = Size(constrains.maxWidth, constrains.maxHeight);
                                imageDisplayRect = _calculateImageRect(_canvasSize);

                                if (editDocController.isCropping && cropPoints.isEmpty) {
                                  _initDefaultCropPoints();
                                }

                                return CustomPaint(
                                  size: Size(constrains.maxWidth, constrains.maxHeight),
                                  painter: DrawCustomLine(
                                    constrains: constrains,
                                    points: editDocController.pointList,
                                    image: image,
                                    cropPoints: editDocController.isCropping ? cropPoints : null,
                                    activeCropIndex: activeCropIndex,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (isProcessingCrop)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 12),
                                  Text(
                                    'Cropping & Enhancing...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: editDocController.isCropping
                            ? buildCropToolbar(editDocController)
                            : (editDocController.isDrawing
                                ? buildDrawFeatureSection(editDocController)
                                : buildEditOptionButtonSection(editDocController)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleCropPanStart(Offset pos) {
    if (cropPoints.length != 4) return;
    const hitRadius = 45.0;
    int? nearest;
    double minDistance = double.infinity;

    for (int i = 0; i < 4; i++) {
      final dist = (cropPoints[i] - pos).distance;
      if (dist < minDistance && dist <= hitRadius) {
        minDistance = dist;
        nearest = i;
      }
    }

    activeCropIndex = nearest;
    setState(() {});
  }

  void _handleCropPanUpdate(Offset pos) {
    if (activeCropIndex == null || imageDisplayRect == null) return;
    final rect = imageDisplayRect!;
    final clampedX = pos.dx.clamp(rect.left, rect.right);
    final clampedY = pos.dy.clamp(rect.top, rect.bottom);

    cropPoints[activeCropIndex!] = Offset(clampedX, clampedY);
    setState(() {});
  }

  Widget buildCropToolbar(EditDocController editDocController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildCustomButton(
          icon: Icons.close,
          onTap: () {
            editDocController.isCropping = false;
            cropPoints.clear();
            editDocController.update();
          },
          title: 'Cancel',
          color: Colors.white70,
        ),
        buildCustomButton(
          icon: Icons.fullscreen,
          onTap: _onResetCrop,
          title: 'Full Image',
          color: Colors.white,
        ),
        buildCustomButton(
          icon: Icons.auto_awesome,
          onTap: () => _onAutoDetectCrop(editDocController),
          title: 'Auto Detect',
          color: const Color(0xFF60A5FA),
        ),
        buildCustomButton(
          icon: Icons.check_circle,
          onTap: () => _onApplyCrop(editDocController),
          title: 'Apply Crop',
          color: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget buildDrawFeatureSection(EditDocController editDocController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                min: 1,
                max: 15,
                value: editDocController.lineWidth,
                onChanged: editDocController.onChangedLineWidth,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...editDocController.colors.asMap().entries.map((colorObject) {
                    final isSelected = editDocController.selectedColorIndex == colorObject.key;
                    return GestureDetector(
                      onTap: () {
                        editDocController.onSelectColor(colorObject.key);
                      },
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorObject.value,
                          border: Border.all(
                            width: isSelected ? 3 : 1,
                            color: isSelected ? Colors.white : Colors.white30,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            editDocController.onTapToDraw();
          },
          icon: const Icon(Icons.check_circle, color: Color(0xFF60A5FA), size: 36),
        ),
      ],
    );
  }

  Widget buildEditOptionButtonSection(EditDocController editDocController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildCustomButton(
          icon: Icons.crop,
          onTap: () => _onEnterCropMode(editDocController),
          title: 'Crop',
          color: editDocController.isCropping ? Colors.blue : Colors.white,
        ),
        buildCustomButton(
          icon: Icons.edit,
          onTap: () {
            editDocController.onTapToDraw();
          },
          title: 'Draw',
          color: editDocController.isDrawing ? Colors.blue : Colors.white,
        ),
        buildCustomButton(
          icon: Icons.rotate_right,
          onTap: () => _onTapRotate(editDocController),
          title: 'Rotate',
        ),
      ],
    );
  }

  Widget buildCustomButton({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    Color? color,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  AppBar buildAppSection(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.black,
      automaticallyImplyLeading: false,
      title: GetBuilder<EditDocController>(
        builder: (editDocController) {
          return Row(
            children: [
              GestureDetector(
                onTap: editDocController.pointList.isNotEmpty
                    ? () => editDocController.onUnDo()
                    : null,
                child: Icon(
                  Icons.undo,
                  color: editDocController.pointList.isNotEmpty
                      ? Colors.white
                      : Colors.white24,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: editDocController.reDoPoints.isNotEmpty
                    ? () => editDocController.onRedo()
                    : null,
                child: Icon(
                  Icons.redo,
                  color: editDocController.reDoPoints.isNotEmpty
                      ? Colors.white
                      : Colors.white24,
                ),
              ),
              const Spacer(),
              Text(
                editDocController.isCropping ? 'Adjust Borders' : 'Edit Page',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _onTapDone(editDocController),
                child: const Icon(Icons.done, color: Color(0xFF60A5FA), size: 28),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DrawCustomLine extends CustomPainter {
  final List<DrawModel> points;
  final BoxConstraints constrains;
  final ui.Image? image;
  final List<Offset>? cropPoints;
  final int? activeCropIndex;

  DrawCustomLine({
    required this.points,
    required this.image,
    required this.constrains,
    this.cropPoints,
    this.activeCropIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageRecorder = ui.PictureRecorder();
    final recordCanvas = Canvas(imageRecorder);

    void renderBaseAndDrawings(Canvas c) {
      if (image != null) {
        paintImage(
          fit: BoxFit.contain,
          canvas: c,
          rect: Rect.fromLTWH(0, 0, constrains.maxWidth, constrains.maxHeight),
          image: image!,
        );
      }

      for (DrawModel line in points) {
        if (line.point.isEmpty) continue;
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..color = line.color
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = line.width;

        for (int i = 0; i < line.point.length - 1; i++) {
          c.drawLine(line.point[i], line.point[i + 1], paint);
        }
      }
    }

    renderBaseAndDrawings(canvas);
    renderBaseAndDrawings(recordCanvas);

    final recordedPicture = imageRecorder.endRecording();
    Get.find<EditDocController>().saveRecordedPicture(recordedPicture);

    // Draw Interactive Crop Overlay if in crop mode (only on screen canvas)
    if (cropPoints != null && cropPoints!.length == 4) {
      final p0 = cropPoints![0];
      final p1 = cropPoints![1];
      final p2 = cropPoints![2];
      final p3 = cropPoints![3];

      final cropPath = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      // Shaded Tint Fill
      final fillPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(cropPath, fillPaint);

      // Border Lines
      final borderPaint = Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(cropPath, borderPaint);

      // Draw 4 Draggable Corner Handles
      for (int i = 0; i < 4; i++) {
        final pt = cropPoints![i];
        final isActive = activeCropIndex == i;

        // Outer glow
        canvas.drawCircle(
          pt,
          isActive ? 18 : 13,
          Paint()..color = (isActive ? Colors.white : Colors.white).withValues(alpha: 0.9),
        );
        // Inner blue circle
        canvas.drawCircle(
          pt,
          isActive ? 11 : 8,
          Paint()..color = const Color(0xFF1D4ED8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
