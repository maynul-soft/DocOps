import 'package:doc_scanner/core/export_path/export_path.dart';

class EditDocController extends GetxController {
  List<List<Offset>> pointList = [];
  bool isDrawing = false;
  List<List<Offset>> reDoPoints = [];

  void addStartOffset(Offset point) {
    pointList.add([point]);
    reDoPoints.clear();
    update();
  }

  void addOffset(Offset point) {
    pointList.last.add(point);
    update();
  }

  void onTapToDraw() {
    isDrawing = true;
    update();
  }

  void onUnDo() {
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
}
