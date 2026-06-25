import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.inter(
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
    return GoogleFonts.notoNastaliqUrdu(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight,
      color: color,
      height: 1.6,
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
