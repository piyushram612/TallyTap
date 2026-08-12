import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'tripl_button.dart';
import 'tripl_icon_badge.dart';

class TriplSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final Widget? trailingAction;
  final bool showCloseButton;
  final EdgeInsetsGeometry padding;

  const TriplSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.trailingAction,
    this.showCloseButton = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.cardBorder, width: 1),
      ),
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            children: [
              if (icon != null) ...[
                TriplIconBadge(icon: icon!),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailingAction,
              if (showCloseButton && trailingAction == null)
                TriplButton.icon(
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Content Body
          Flexible(child: child),
        ],
      ),
    );
  }
}

Future<T?> showTriplSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  IconData? icon,
  required Widget child,
  Widget? trailingAction,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TriplSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailingAction: trailingAction,
      child: child,
    ),
  );
}
