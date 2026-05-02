import 'package:opencv_dart/opencv_dart.dart' as cv;

void main() {
  final points = cv.VecPoint.fromList([
    cv.Point(10, 10),
    cv.Point(100, 15),
    cv.Point(105, 100),
    cv.Point(15, 95),
    cv.Point(50, 50),
  ]);
  
  final rect = cv.boundingRect(points);
  print('Bounding rect: x=${rect.x}, y=${rect.y}, w=${rect.width}, h=${rect.height}');
  
  final minRect = cv.minAreaRect(points);
  print('Min area rect: center=(${minRect.center.x}, ${minRect.center.y}), size=(${minRect.size.width}, ${minRect.size.height}), angle=${minRect.angle}');
  
  // Get 4 corners of minAreaRect
  final pts = minRect.points;
  print('Min area rect points: $pts');
}
