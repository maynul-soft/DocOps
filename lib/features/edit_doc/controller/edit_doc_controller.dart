import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/edit_doc/model/draw_model.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class EditDocController extends GetxController {
  List<DrawModel> pointList = [];
  bool isDrawing = false;
  List<DrawModel> reDoPoints = [];
  double lineWidth = 3.0;
  int selectedColorIndex = 0;
  ui.Picture? recordedPicture;

  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.black,
    Colors.white,
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
    if (pointList.isNotEmpty) {
      pointList.last.point.add(point);
      update();
    }
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
    update();
  }

  void onSelectColor(int index) {
    selectedColorIndex = index;
    update();
  }

  void saveRecordedPicture(ui.Picture picture) {
    recordedPicture = picture;
  }

  /// Saves the rendered canvas overlay into the physical image file
  Future<bool> saveEditedImage({
    required String imagePath,
    required int width,
    required int height,
  }) async {
    try {
      if (recordedPicture == null) return false;

      final uiImage = await recordedPicture!.toImage(width, height);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final file = File(imagePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      Logger().i('Saved edited image to $imagePath');
      return true;
    } catch (e) {
      Logger().e('Failed to save edited image: $e');
      return false;
    }
  }

  /// Rotates the image 90 degrees clockwise using OpenCV
  Future<bool> rotateImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      final rotated = cv.rotate(mat, cv.ROTATE_90_CLOCKWISE);
      final (success, encoded) = cv.imencode('.jpg', rotated);

      if (success) {
        await file.writeAsBytes(encoded);
      }

      mat.dispose();
      rotated.dispose();
      update();
      return success;
    } catch (e) {
      Logger().e('Failed to rotate image: $e');
      return false;
    }
  }

  Future<ui.Image?> convertImage(String filePath) async {
    try {
      final File loadedImage = File(filePath);
      if (!await loadedImage.exists()) return null;

      final Uint8List bytes = await loadedImage.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      Logger().e('Failed to load ui.Image: $e');
      return null;
    }
  }
}
