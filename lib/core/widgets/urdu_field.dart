import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../utils/icon_colors.dart';

class UrduField extends StatelessWidget {
  const UrduField({
    required this.controller,
    required this.label,
    super.key,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            prefixIcon == null ? null : IconColors.icon(prefixIcon!, size: 22),
      ),
      onChanged: onChanged,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: AppTextStyles.urdu(fontSize: 16),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
