import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class TriplCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final double borderWidth;
  final CrossAxisAlignment crossAxisAlignment;

  const TriplCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.borderRadius = 24.0,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.borderWidth = 1.0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? context.cardBg;
    final effectiveBorder = borderColor ?? context.cardBorder;

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }

    return container;
  }
}
