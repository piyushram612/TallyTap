import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum TriplButtonVariant { primary, secondary, ghost, icon }

class TriplButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TriplButtonVariant variant;
  final bool isLoading;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double size;

  const TriplButton({
    super.key,
    this.label,
    required this.onPressed,
    this.icon,
    this.variant = TriplButtonVariant.primary,
    this.isLoading = false,
    this.borderRadius = 14.0,
    this.padding,
    this.color,
    this.size = 40.0,
  });

  const TriplButton.primary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.borderRadius = 14.0,
    this.padding,
    this.color,
  })  : variant = TriplButtonVariant.primary,
        size = 40.0;

  const TriplButton.secondary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.borderRadius = 14.0,
    this.padding,
    this.color,
  })  : variant = TriplButtonVariant.secondary,
        size = 40.0;

  const TriplButton.ghost({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.padding,
    this.color,
  })  : variant = TriplButtonVariant.ghost,
        isLoading = false,
        borderRadius = 14.0,
        size = 40.0;

  const TriplButton.icon({
    super.key,
    required IconData this.icon,
    required this.onPressed,
    this.size = 36.0,
    this.color,
  })  : label = null,
        variant = TriplButtonVariant.icon,
        isLoading = false,
        borderRadius = 10.0,
        padding = null;

  @override
  Widget build(BuildContext context) {
    if (variant == TriplButtonVariant.icon) {
      return GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: context.cardBorder, width: 0.5),
          ),
          child: Icon(
            icon,
            color: color ?? context.primaryAccent,
            size: size * 0.5,
          ),
        ),
      );
    }

    final accent = color ?? context.primaryAccent;

    Color bg;
    Color fg;
    BorderSide border;

    switch (variant) {
      case TriplButtonVariant.primary:
        bg = accent;
        fg = accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
        border = BorderSide.none;
        break;
      case TriplButtonVariant.secondary:
        bg = context.cardBg;
        fg = context.textPrimary;
        border = BorderSide(color: context.cardBorder, width: 1.0);
        break;
      case TriplButtonVariant.ghost:
        bg = Colors.transparent;
        fg = accent;
        border = BorderSide.none;
        break;
      default:
        bg = accent;
        fg = Colors.black;
        border = BorderSide.none;
    }

    final contentPadding = padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: contentPadding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: fg,
                  fontFamily: 'Outfit',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
