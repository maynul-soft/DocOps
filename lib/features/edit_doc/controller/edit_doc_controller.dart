import 'dart:typed_data';
import 'dart:io';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/edit_doc/model/draw_model.dart';
import 'dart:ui' as ui;

class EditDocController extends GetxController {
  List<DrawModel> pointList = [];
  bool isDrawing = false;
  List<DrawModel> reDoPoints = [];
  double lineWidth = 1;
  int selectedColorIndex = 0;
  ui.Picture? recordedPicture;

  final List<Color> colors = [
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  void addStartOffset(Offset point) {
    pointList.add(
      DrawModel(
        point: [point],
        color: colors[selectedColorIndex],
        width: lineWidth,
      ),
    );
    reDoPoints.clear();
    update();
  }

  void addOffset(Offset point) {
    pointList.last.point.add(point);
    update();
  }

  void onTapToDraw() {
    isDrawing = !isDrawing;
    update();
  }

  void onUnDo() {
    if (pointList.isEmpty) return;
    reDoPoints.add(pointList.last);
    pointList.removeLast();
    update();
  }

  void onRedo() {
    if (reDoPoints.isEmpty) return;
    pointList.add(reDoPoints.last);
    reDoPoints.removeLast();
    update();
  }

  void onChangedLineWidth(double width) {
    lineWidth = width;
    // debugPrint("width ${1 * width}");
    update();
  }

  void onSelectColor(int index) {
    selectedColorIndex = index;
    update();
  }

  void saveRecordedPicture(ui.Picture picture){
    recordedPicture = recordedPicture;
  }

  void saveEditedImage({required String imagePath, required ui.Image image}){
    if (recordedPicture == null)return;

    File file = File(imagePath);

    // final image = recordedPicture!.toImage(image.width, height)
  }



  Future<ui.Image?> convertImage(String filePath) async {
    ui.Image? image;
    try {
      final File loadedImage = File(filePath);
      final Uint8List bytes = await loadedImage.readAsBytes();
      Logger().e('Image bytes $bytes');
      ui.Codec codec = await ui.instantiateImageCodec(bytes);
      Logger().e("Codec$codec");
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      image = frameInfo.image;
      return image;
    } catch (e) {
      Logger().e('Failed to load image $e');
      return image;
    }
  }
}
