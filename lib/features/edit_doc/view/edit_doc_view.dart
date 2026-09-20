import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/edit_doc/controller/edit_doc_controller.dart';
import 'dart:ui' as ui;
import 'package:doc_scanner/features/edit_doc/model/draw_model.dart';

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
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadImage();
    });
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  void _onTapDone(EditDocController controller) async {
    final path = activeImagePath;
    if (path == null) {
      Get.back();
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
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (!editDocController.isDrawing) return;
                        editDocController.addStartOffset(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        if (!editDocController.isDrawing) return;
                        editDocController.addOffset(details.localPosition);
                      },
                      onPanEnd: (details) {
                        if (!editDocController.isDrawing) return;
                        editDocController.addOffset(details.localPosition);
                      },
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constrains) {
                          _canvasSize = Size(constrains.maxWidth, constrains.maxHeight);
                          return CustomPaint(
                            size: Size(constrains.maxWidth, constrains.maxHeight),
                            painter: DrawCustomLine(
                              constrains: constrains,
                              points: editDocController.pointList,
                              image: image,
                            ),
                          );
                        },
                      ),
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
                        child: !editDocController.isDrawing
                            ? buildEditOptionButtonSection(editDocController)
                            : buildDrawFeatureSection(editDocController),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const Text(
                'Edit Page',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

  DrawCustomLine({
    required this.points,
    required this.image,
    required this.constrains,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageRecorder = ui.PictureRecorder();
    final recordCanvas = Canvas(imageRecorder);

    void renderContent(Canvas c) {
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

    renderContent(canvas);
    renderContent(recordCanvas);

    final recordedPicture = imageRecorder.endRecording();
    Get.find<EditDocController>().saveRecordedPicture(recordedPicture);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
