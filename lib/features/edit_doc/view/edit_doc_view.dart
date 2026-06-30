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

  void loadImage() async {
    // Logger().e('Image Path status ${widget.imagePath}');

    if (widget.imagePath == null) return;
    Logger().e('Image Path status ${widget.imagePath}');

    final loadedImage = await Get.find<EditDocController>().convertImage(
      widget.imagePath!,
    );
    image = loadedImage;

    Logger().e('Loaded Image: $loadedImage');

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPersistentFrameCallback((Duration duration) {
    //   loadImage();
    // });
    loadImage();
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
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
                  margin: EdgeInsets.only(top: 20),
                  height: size.height - 250,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(50)),
                  // child: widget.imagePath != null
                  //     ? Image.file(File(widget.imagePath!), fit: BoxFit.contain)
                  //     :
                  child: GestureDetector(
                    onPanStart: (details) {
                      if (!editDocController.isDrawing) return;

                      editDocController.addStartOffset(details.localPosition);
                      // Logger().d('start ${details.localPosition}');
                    },
                    onPanUpdate: (details) {
                      if (!editDocController.isDrawing) return;
                      // Logger().d('update ${details.localPosition}');
                      editDocController.addOffset(details.localPosition);
                    },
                    onPanEnd: (details) {
                      if (!editDocController.isDrawing) return;
                      // Logger().d('end ${details.localPosition}');
                      editDocController.addOffset(details.localPosition);
                    },
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constrains) {
                            return Container(
                              color: Colors.blue,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRect(
                                      child: CustomPaint(
                                        size: Size(
                                          constrains.maxWidth,
                                          constrains.maxWidth,
                                        ),
                                        painter: DrawCustomLine(
                                          constrains: constrains,
                                          points: editDocController.pointList,
                                          image: image,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                    ),
                  ),
                ),
                Gap.height(10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: .center,
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
      mainAxisAlignment: .start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Slider(
                min: 1,
                max: 20,
                value: editDocController.lineWidth,
                onChanged: editDocController.onChangedLineWidth,
              ),
              Gap.height(5),
              Row(
                mainAxisAlignment: .spaceAround,
                children: [
                  ...editDocController.colors.asMap().entries.map((
                    colorObject,
                  ) {
                    return GestureDetector(
                      onTap: () {
                        editDocController.onSelectColor(colorObject.key);
                      },
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorObject.value,
                          border: Border.all(
                            width:
                                editDocController.selectedColorIndex ==
                                    colorObject.key
                                ? 3
                                : 0,
                            color: Colors.grey.withAlpha(500),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              Gap.height(20),
            ],
          ),
        ),
        Gap.width(10),

        IconButton(
          onPressed: () {
            editDocController.onTapToDraw();
          },
          icon: Icon(Icons.done, color: Colors.white, size: 35),
        ),
      ],
    );
  }

  Widget buildEditOptionButtonSection(EditDocController editDocController) {
    return Row(
      mainAxisAlignment: .spaceAround,
      children: [
        buildCustomButton(icon: Icons.crop, onTap: () {}, title: 'crop'),
        buildCustomButton(
          icon: Icons.edit,
          onTap: () {
            editDocController.onTapToDraw();
          },
          title: 'draw',
        ),

        // buildCustomButton(
        //   icon: Icons.auto_fix_high_outlined,
        //   onTap: () {},
        //   title: 'erase',
        // ),
        buildCustomButton(
          icon: Icons.rotate_left,
          onTap: () {},
          title: 'rotate',
        ),
      ],
    );
  }

  GestureDetector buildCustomButton({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    Color? color,
  }) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, color: color ?? Colors.white),
        Text(
          title,
          style: CustomTextTheme.fontSize9(context)
              .copyWith(fontWeight: FontWeight.bold)
              .copyWith(color: color ?? Colors.white),
        ),
      ],
    ),
  );

  AppBar buildAppSection(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.black,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: GetBuilder<EditDocController>(
        builder: (editDocController) {
          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  editDocController.onUnDo();
                },
                child: Transform.flip(
                  flipX: true,
                  child: Icon(
                    Icons.shortcut,
                    color: editDocController.pointList.isNotEmpty
                        ? Colors.white
                        : Colors.grey,
                  ),
                ),
              ),
              Gap.width(16),
              GestureDetector(
                onTap: () {
                  editDocController.onRedo();
                },
                child: Icon(
                  Icons.shortcut,
                  color: editDocController.reDoPoints.isNotEmpty
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
              Spacer(),
              Text(
                'Edit Scan',
                style: CustomTextTheme.fontSize18bold(
                  context,
                ).copyWith(color: Colors.white),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.close, color: Colors.white),
              ),
              Gap.width(16),
              GestureDetector(
                onTap: () {},
                child: Icon(Icons.done, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DrawCustomLine extends CustomPainter {
  List<DrawModel> points;
  BoxConstraints constrains;
  ui.Image? image;

  DrawCustomLine({
    required this.points,
    required this.image,
    required this.constrains,
  });

  EditDocController docController = Get.find<EditDocController>();

  @override
  void paint(Canvas canvas, Size size) {
    final imageRecorder = ui.PictureRecorder();

    if (image != null) {
      Logger().e('image painting');
      paintImage(
        fit: BoxFit.cover,
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, constrains.maxWidth, constrains.maxHeight),
        image: image!,
      );
    }

    for (DrawModel line in points) {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..color = line.color
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = line.width;

      if (points.isEmpty) return;

      for (int i = 0; i < line.point.length - 1; i++) {
        canvas.drawLine(line.point[i], line.point[i + 1], paint);
      }
    }

    final recordedPicture = imageRecorder.endRecording();
    Get.find<EditDocController>().saveRecordedPicture(recordedPicture);

    // canvas.drawLine(p1, p2, paint)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
