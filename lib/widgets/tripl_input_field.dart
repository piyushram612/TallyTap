import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class TriplInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final String? prefixText;
  final bool autofocus;

  const TriplInputField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.prefixText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textMuted),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: context.primaryAccent,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: context.textMuted, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: context.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.cardBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
