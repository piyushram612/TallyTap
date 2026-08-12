import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class TriplBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const TriplBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.primaryAccent;
    final effectiveBg = backgroundColor ?? effectiveColor.withOpacity(0.15);

    final widget = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? effectiveColor : effectiveBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? effectiveColor : effectiveColor.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isSelected ? Colors.black : effectiveColor,
              size: 12,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isSelected ? Colors.black : effectiveColor,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }
}

class TriplPillToggle<T> extends StatelessWidget {
  final List<T> options;
  final T selectedValue;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onSelected;

  const TriplPillToggle({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selectedValue;
          final label = labelBuilder(option).toUpperCase();

          return GestureDetector(
            onTap: () => onSelected(option),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? context.primaryAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? (context.primaryAccent.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                      : context.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
