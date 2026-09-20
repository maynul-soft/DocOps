import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  static Future<ui.Image?> show(BuildContext context) {
    return showModalBottomSheet<ui.Image>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SignatureDialog(),
    );
  }

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _SignatureStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class _SignatureDialogState extends State<SignatureDialog> {
  final List<_SignatureStroke> _strokes = [];
  final List<_SignatureStroke> _redoStrokes = [];

  Color _selectedColor = const Color(0xFF0F172A); // Dark ink
  double _strokeWidth = 3.5;

  final List<Color> _penColors = [
    const Color(0xFF0F172A), // Charcoal / Black
    const Color(0xFF1E3A8A), // Navy Blue
    const Color(0xFF2563EB), // Royal Blue
    const Color(0xFFDC2626), // Official Red
  ];

  void _clear() {
    setState(() {
      _strokes.clear();
      _redoStrokes.clear();
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStrokes.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStrokes.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStrokes.removeLast());
      });
    }
  }

  Future<void> _exportSignature() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Find bounding box of all strokes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final stroke in _strokes) {
      for (final p in stroke.points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    const padding = 16.0;
    minX = (minX - padding).clamp(0.0, double.infinity);
    minY = (minY - padding).clamp(0.0, double.infinity);
    maxX += padding;
    maxY += padding;

    final width = (maxX - minX).ceil();
    final height = (maxY - minY).ceil();

    if (width <= 0 || height <= 0) {
      Navigator.pop(context);
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Translate to top-left of crop rect
    canvas.translate(-minX, -minY);

    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points[0],
          stroke.strokeWidth / 2,
          Paint()..color = stroke.color,
        );
      } else {
        final path = Path();
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (int i = 1; i < stroke.points.length - 1; i++) {
          final p0 = stroke.points[i];
          final p1 = stroke.points[i + 1];
          final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        }
        path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
        canvas.drawPath(path, paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);

    if (mounted) {
      Navigator.pop(context, image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.draw, color: Color(0xFF60A5FA), size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Digital Signature',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Undo',
                      icon: Icon(
                        Icons.undo,
                        color: _strokes.isNotEmpty ? Colors.white : Colors.white24,
                        size: 20,
                      ),
                      onPressed: _strokes.isNotEmpty ? _undo : null,
                    ),
                    IconButton(
                      tooltip: 'Redo',
                      icon: Icon(
                        Icons.redo,
                        color: _redoStrokes.isNotEmpty ? Colors.white : Colors.white24,
                        size: 20,
                      ),
                      onPressed: _redoStrokes.isNotEmpty ? _redo : null,
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: _strokes.isNotEmpty ? _clear : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Signature Drawing Canvas
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Baseline indicator
                    Positioned(
                      bottom: 45,
                      left: 24,
                      right: 24,
                      child: Row(
                        children: [
                          const Text(
                            '✕ ',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Sign above the line with your finger',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    // Gesture drawing canvas
                    GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _strokes.add(
                            _SignatureStroke(
                              points: [details.localPosition],
                              color: _selectedColor,
                              strokeWidth: _strokeWidth,
                            ),
                          );
                          _redoStrokes.clear();
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          if (_strokes.isNotEmpty) {
                            _strokes.last.points.add(details.localPosition);
                          }
                        });
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _SignaturePadPainter(strokes: _strokes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Pen Controls (Colors & Width)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ink Colors
                Row(
                  children: _penColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                // Stroke Width options
                Row(
                  children: [
                    _buildStrokeOption(label: 'Fine', width: 2.0),
                    const SizedBox(width: 8),
                    _buildStrokeOption(label: 'Normal', width: 3.5),
                    const SizedBox(width: 8),
                    _buildStrokeOption(label: 'Bold', width: 5.0),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _exportSignature,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Insert Signature', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeOption({required String label, required double width}) {
    final isSelected = _strokeWidth == width;
    return GestureDetector(
      onTap: () => setState(() => _strokeWidth = width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF334155) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF60A5FA) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF60A5FA) : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SignaturePadPainter extends CustomPainter {
  final List<_SignatureStroke> strokes;

  _SignaturePadPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points[0],
          stroke.strokeWidth / 2,
          Paint()..color = stroke.color,
        );
      } else {
        final path = Path();
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (int i = 1; i < stroke.points.length - 1; i++) {
          final p0 = stroke.points[i];
          final p1 = stroke.points[i + 1];
          final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        }
        path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}
