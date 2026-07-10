import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const String _interFamily = 'Roboto';

  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: kIsWeb ? null : _interFamily,
      fontFamilyFallback: kIsWeb ? null : const ['sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle urdu({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight,
      color: color,
      height: kIsWeb ? null : 1.6,
    );
  }

  static TextStyle forLocale(
    bool isUrdu, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return isUrdu
        ? urdu(fontSize: fontSize, fontWeight: fontWeight, color: color)
        : inter(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}
