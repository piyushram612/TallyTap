import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class TriplIconBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const TriplIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.primaryAccent;
    final effectiveBg = backgroundColor ?? context.cardBg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      child: Icon(
        icon,
        color: effectiveColor,
        size: iconSize,
      ),
    );
  }
}
