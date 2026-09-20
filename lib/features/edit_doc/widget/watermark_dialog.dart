import 'package:flutter/material.dart';

class WatermarkConfig {
  String text;
  Color color;
  double opacity;
  double angle; // degrees: -45.0, 0.0, 45.0, 90.0
  double fontSize;
  bool isRepeated;

  WatermarkConfig({
    required this.text,
    this.color = const Color(0xFF64748B),
    this.opacity = 0.25,
    this.angle = -45.0,
    this.fontSize = 32.0,
    this.isRepeated = false,
  });

  WatermarkConfig copyWith({
    String? text,
    Color? color,
    double? opacity,
    double? angle,
    double? fontSize,
    bool? isRepeated,
  }) {
    return WatermarkConfig(
      text: text ?? this.text,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      angle: angle ?? this.angle,
      fontSize: fontSize ?? this.fontSize,
      isRepeated: isRepeated ?? this.isRepeated,
    );
  }
}

class WatermarkResult {
  final WatermarkConfig? config;
  final bool isRemoved;

  WatermarkResult({this.config, this.isRemoved = false});
}

class WatermarkDialog extends StatefulWidget {
  final WatermarkConfig? initialConfig;

  const WatermarkDialog({super.key, this.initialConfig});

  static Future<WatermarkResult?> show(
    BuildContext context, {
    WatermarkConfig? initialConfig,
  }) {
    return showModalBottomSheet<WatermarkResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatermarkDialog(initialConfig: initialConfig),
    );
  }

  @override
  State<WatermarkDialog> createState() => _WatermarkDialogState();
}

class _WatermarkDialogState extends State<WatermarkDialog> {
  late TextEditingController _textController;
  late Color _selectedColor;
  late double _opacity;
  late double _angle;
  late bool _isRepeated;

  final List<String> _presets = [
    'CONFIDENTIAL',
    'DO NOT COPY',
    'ORIGINAL',
    'COPY',
    'PAID',
    'URGENT',
    'SAMPLE',
    'DRAFT',
  ];

  final List<Color> _colors = [
    const Color(0xFF64748B), // Slate Grey
    const Color(0xFFDC2626), // Crimson Red
    const Color(0xFF1E3A8A), // Navy Blue
    const Color(0xFF059669), // Emerald Green
    const Color(0xFFD97706), // Amber
    const Color(0xFF0F172A), // Dark Black
  ];

  final List<Map<String, dynamic>> _angles = [
    {'label': '-45° Diagonal', 'angle': -45.0, 'icon': Icons.south_east},
    {'label': '0° Horizontal', 'angle': 0.0, 'icon': Icons.arrow_forward},
    {'label': '45° Diagonal', 'angle': 45.0, 'icon': Icons.north_east},
    {'label': '90° Vertical', 'angle': 90.0, 'icon': Icons.arrow_upward},
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialConfig;
    _textController = TextEditingController(text: init?.text ?? 'CONFIDENTIAL');
    _selectedColor = init?.color ?? const Color(0xFF64748B);
    _opacity = init?.opacity ?? 0.25;
    _angle = init?.angle ?? -45.0;
    _isRepeated = init?.isRepeated ?? false;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _apply() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text')),
      );
      return;
    }

    final config = WatermarkConfig(
      text: text,
      color: _selectedColor,
      opacity: _opacity,
      angle: _angle,
      fontSize: 32.0,
      isRepeated: _isRepeated,
    );

    Navigator.pop(context, WatermarkResult(config: config));
  }

  void _remove() {
    Navigator.pop(context, WatermarkResult(isRemoved: true));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.branding_watermark_outlined, color: Colors.blueAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Custom Watermark',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.initialConfig != null)
                  TextButton.icon(
                    onPressed: _remove,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                    label: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Watermark Text Input
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                hintText: 'Watermark text (e.g. CONFIDENTIAL)',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () => _textController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Preset Quick Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _textController.text.trim() == preset;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _textController.text = preset;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      preset,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Color Picker
            const Text(
              'Color',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Opacity Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Opacity',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_opacity * 100).toInt()}%',
                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            Slider(
              value: _opacity,
              min: 0.10,
              max: 0.60,
              divisions: 10,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white12,
              onChanged: (val) => setState(() => _opacity = val),
            ),
            const SizedBox(height: 12),

            // Angle Selection
            const Text(
              'Rotation Angle',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _angles.map((item) {
                final isSelected = (_angle - (item['angle'] as double)).abs() < 1;
                return GestureDetector(
                  onTap: () => setState(() => _angle = item['angle'] as double),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Repeated Pattern Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Page Repeated Grid',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Repeat watermark diagonally across page',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isRepeated,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: (val) => setState(() => _isRepeated = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _apply,
                icon: const Icon(Icons.check, size: 20),
                label: const Text(
                  'Apply Watermark',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
