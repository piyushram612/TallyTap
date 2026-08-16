import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'tripl_button.dart';

/// An interactive HSV Color Wheel widget that renders a full hue/saturation spectrum disk
/// and allows intuitive touch/drag selection.
class TriplColorWheel extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final double size;

  const TriplColorWheel({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.size = 220,
  });

  @override
  State<TriplColorWheel> createState() => _TriplColorWheelState();
}

class _TriplColorWheelState extends State<TriplColorWheel> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(covariant TriplColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      final newHsv = HSVColor.fromColor(widget.initialColor);
      if ((newHsv.hue - _hsvColor.hue).abs() > 0.1 ||
          (newHsv.saturation - _hsvColor.saturation).abs() > 0.01 ||
          (newHsv.value - _hsvColor.value).abs() > 0.01) {
        setState(() {
          _hsvColor = newHsv;
        });
      }
    }
  }

  void _handleTouch(Offset localPosition, Size widgetSize) {
    final center = Offset(widgetSize.width / 2, widgetSize.height / 2);
    final radius = math.min(widgetSize.width, widgetSize.height) / 2;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final distance = math.sqrt(dx * dx + dy * dy);
    final saturation = (distance / radius).clamp(0.0, 1.0);

    // Calculate angle in radians, convert to degrees (0..360)
    double radians = math.atan2(dy, dx);
    double degrees = radians * (180 / math.pi);
    if (degrees < 0) degrees += 360;

    final updatedHsv = HSVColor.fromAHSV(
      1.0,
      degrees,
      saturation,
      _hsvColor.value.clamp(0.01, 1.0),
    );

    setState(() {
      _hsvColor = updatedHsv;
    });

    widget.onColorChanged(updatedHsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      child: GestureDetector(
        onPanStart: (details) => _handleTouch(details.localPosition, Size(widget.size, widget.size)),
        onPanUpdate: (details) => _handleTouch(details.localPosition, Size(widget.size, widget.size)),
        onTapDown: (details) => _handleTouch(details.localPosition, Size(widget.size, widget.size)),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ColorWheelPainter(hsvColor: _hsvColor, isDark: isDark),
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final HSVColor hsvColor;
  final bool isDark;

  _ColorWheelPainter({required this.hsvColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 0. Soft Outer Shadow Ring for Depth & Contrast
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final wheelRadius = radius - 1.0;

    // 1. Draw Hue Spectrum Sweep Gradient
    final sweepGradient = SweepGradient(
      colors: const [
        Color(0xFFFF0000), // Red
        Color(0xFFFFFF00), // Yellow
        Color(0xFF00FF00), // Green
        Color(0xFF00FFFF), // Cyan
        Color(0xFF0000FF), // Blue
        Color(0xFFFF00FF), // Magenta
        Color(0xFFFF0000), // Red
      ],
    );

    final wheelPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: wheelRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, wheelRadius, wheelPaint);

    // 2. Overlay Saturation Radial Gradient (white at center, transparent at edge)
    final radialGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 1.0 - (1.0 - hsvColor.value * 0.2)),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    final saturationPaint = Paint()
      ..shader = radialGradient.createShader(Rect.fromCircle(center: center, radius: wheelRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, wheelRadius, saturationPaint);

    // 3. Overlay Value/Darkness mask if value < 1.0
    if (hsvColor.value < 0.99) {
      final darknessPaint = Paint()
        ..color = Colors.black.withValues(alpha: 1.0 - hsvColor.value)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, wheelRadius, darknessPaint);
    }

    // 4. Adaptive Outer Border (White for Dark Mode, Black for Light Mode)
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : Colors.black.withValues(alpha: 0.25);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, wheelRadius, borderPaint);

    // 5. Draw Thumb Selector Ring Handle
    final angleRad = hsvColor.hue * (math.pi / 180);
    final dist = hsvColor.saturation * radius;
    final thumbOffset = Offset(
      center.dx + dist * math.cos(angleRad),
      center.dy + dist * math.sin(angleRad),
    );

    final thumbColor = hsvColor.toColor();
    final isDarkThumb = thumbColor.computeLuminance() < 0.5;

    // Thumb outer shadow
    canvas.drawCircle(
      thumbOffset,
      12,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Thumb outer ring
    canvas.drawCircle(
      thumbOffset,
      11,
      Paint()
        ..color = isDarkThumb ? Colors.white : Colors.black
        ..style = PaintingStyle.fill,
    );

    // Thumb inner ring
    canvas.drawCircle(
      thumbOffset,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Thumb color fill center
    canvas.drawCircle(
      thumbOffset,
      7,
      Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.hsvColor != hsvColor || oldDelegate.isDark != isDark;
  }
}

/// Modal Dialog providing a full custom accent color picker experience
/// featuring an interactive color wheel, brightness slider, hex text field, and quick swatches.
class TriplColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onApply;
  final AppThemeConfig themeConfig;

  const TriplColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onApply,
    required this.themeConfig,
  });

  static Future<void> show(
    BuildContext context, {
    required Color initialColor,
    required AppThemeConfig themeConfig,
    required ValueChanged<Color> onApply,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TriplColorPickerDialog(
        initialColor: initialColor,
        onApply: onApply,
        themeConfig: themeConfig,
      ),
    );
  }

  @override
  State<TriplColorPickerDialog> createState() => _TriplColorPickerDialogState();
}

class _TriplColorPickerDialogState extends State<TriplColorPickerDialog> {
  late Color _currentColor;
  late HSVColor _hsvColor;
  late TextEditingController _hexController;

  static const List<Color> _quickSwatches = [
    Color(0xFF4EDEA3), // Mint Green
    Color(0xFF8B5CF6), // Electric Violet
    Color(0xFF38BDF8), // Sky Cyan
    Color(0xFFF59E0B), // Amber Gold
    Color(0xFFF43F5E), // Rose Pink
    Color(0xFF22C55E), // Electric Lime
    Color(0xFFEC4899), // Hot Pink
    Color(0xFF6366F1), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hsvColor = HSVColor.fromColor(_currentColor);
    _hexController = TextEditingController(
      text: _colorToHex(_currentColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  void _updateColor(Color newColor, {bool updateHexField = true}) {
    setState(() {
      _currentColor = newColor;
      _hsvColor = HSVColor.fromColor(newColor);
      if (updateHexField) {
        _hexController.text = _colorToHex(newColor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.themeConfig;
    final isDarkText = _currentColor.computeLuminance() > 0.5;

    return AlertDialog(
      backgroundColor: cfg.cardBg,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cfg.cardBorder, width: 1),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.color_lens_rounded, color: _currentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Custom Accent Color',
                style: TextStyle(
                  color: cfg.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: cfg.textMuted, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live Preview Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cfg.cardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '#${_colorToHex(_currentColor)}',
                style: TextStyle(
                  color: isDarkText ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Color Wheel Component
            TriplColorWheel(
              initialColor: _currentColor,
              size: 210,
              onColorChanged: (color) {
                _updateColor(color);
              },
            ),
            const SizedBox(height: 18),

            // Brightness / Value Slider
            Row(
              children: [
                Icon(Icons.brightness_6_rounded, color: cfg.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _currentColor,
                      inactiveTrackColor: cfg.cardBorder,
                      thumbColor: Colors.white,
                      overlayColor: _currentColor.withValues(alpha: 0.2),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _hsvColor.value.clamp(0.01, 1.0),
                      min: 0.01,
                      max: 1.0,
                      onChanged: (val) {
                        final updated = _hsvColor.withValue(val).toColor();
                        _updateColor(updated);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Swatches Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickSwatches.map((color) {
                final isSelected = _currentColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => _updateColor(color),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? cfg.textPrimary : Colors.transparent,
                        width: isSelected ? 2.5 : 0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Hex Input Field
            TextField(
              controller: _hexController,
              style: TextStyle(color: cfg.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                prefixText: '# ',
                prefixStyle: TextStyle(color: _currentColor, fontWeight: FontWeight.bold, fontSize: 16),
                labelText: 'Hex Color Code',
                labelStyle: TextStyle(color: cfg.textMuted, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cfg.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _currentColor, width: 2),
                ),
              ),
              onChanged: (val) {
                if (val.length == 6) {
                  final hex = int.tryParse('FF$val', radix: 16);
                  if (hex != null) {
                    _updateColor(Color(hex), updateHexField: false);
                  }
                }
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TriplButton.ghost(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TriplButton.primary(
                label: 'Apply Accent',
                color: _currentColor,
                onPressed: () {
                  widget.onApply(_currentColor);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
