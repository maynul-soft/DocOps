import 'dart:io';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/edit_doc/controller/edit_doc_controller.dart';

class EditDocView extends StatefulWidget {
  final String? imagePath;
  const EditDocView({super.key, this.imagePath});

  static const name = 'EditDocView';

  @override
  State<EditDocView> createState() => _EditDocViewState();
}

class _EditDocViewState extends State<EditDocView> {
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
                  child: widget.imagePath != null
                      ? Image.file(File(widget.imagePath!), fit: BoxFit.contain)
                      : GestureDetector(
                          onPanStart: (details) {
                            if (!editDocController.isDrawing) return;

                            editDocController.addStartOffset(
                              details.localPosition,
                            );
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
                          child: Container(
                            height: 100,
                            width: 100,
                            color: Colors.blue,
                            child: Stack(
                              children: [
                                ...editDocController.pointList
                                    .asMap()
                                    .entries
                                    .map((element) {
                                      return Positioned.fill(
                                        child: CustomPaint(
                                          painter: DrawCustomLine(
                                            points: element.value,
                                          ),
                                        ),
                                      );
                                    }),
                              ],
                            ),

                            // child: CustomPaint(
                            //   painter: DrawCustomLine(
                            //     points: editDocController.pointList,
                            //   ),
                            // ),

                            // child: CustomPaint(
                            //   size: Size(double.maxFinite, double.maxFinite),
                            //   painter: CustomPaintObject(),
                            // ),
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
                            : Row(children: [
                          
                         ],),
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
  List<Offset> points;

  DrawCustomLine({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = Colors.white
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (points.isEmpty) return;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // canvas.drawLine(p1, p2, paint)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}





// class CustomPaintObject extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
    
//     final paint = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 5
//       ..strokeJoin = StrokeJoin.round
//       ..style = PaintingStyle.fill;

//     //  final rect = Rect.fromLTWH(10, 10, 100, 200);
//     //   canvas.drawRect(rect, paint);

//     // final List<Offset> offset = [Offset(10, 10), Offset(200,10),Offset(100, 100),Offset(10, 10)];
//     // there are three type in PointMode = polygon, point, line
//     // canvas.drawPoints(PointMode.polygon, offset, paint);

//     // final RRect rRect = RRect.fromLTRBAndCorners(
//     //   10,
//     //   10,
//     //   100,
//     //   200,
//     //   topLeft: Radius.circular(10),
//     // );
//     // canvas.drawRRect(rRect, paint);

//     // final path = Path()
//     // ..moveTo(10, 10)
//     // ..lineTo(100, 10)
//     // ..lineTo(100, 150)
//     // ..lineTo(10, 150)
//     // ..close();


//     // final curvePath = Path()
//     // ..moveTo(10, 10)
//     // ..quadraticBezierTo(100, 10, 100, 150)
//     // ..quadraticBezierTo(10, 150, 10, 100)
//     // ..close()
//     // ;

//     // final curveLine = Path()
//     // ..moveTo(10, 10)
//     // ..lineTo(90, 10)
//     // ..quadraticBezierTo(100, 10, 100, 20)
//     // ..lineTo(100, 150)
//     // ;

//     // draw with path

//     // final ticket = Path()
//     // ..moveTo(10, 10)
//     // ..lineTo(200, 10)
//     // ..quadraticBezierTo(210, 40, 230, 40)
//     // ..quadraticBezierTo(250, 40, 260, 10)
//     // ..lineTo(290, 10)
//     // ..lineTo(290, 150)
//     // ..lineTo(260, 150)
//     // ..quadraticBezierTo(250, 120, 230, 120)
//     // ..quadraticBezierTo(210, 120, 200, 150)
//     // ..lineTo(10, 150)
//     // ..close();



  
//     canvas.drawLine(Offset(10, 10), Offset(100,10), paint);

//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

 

