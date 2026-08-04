import 'package:flutter/material.dart';

/// Stable palette for icons — same icon always gets same color.
class IconColors {
  IconColors._();

  static const palette = <Color>[
    Color(0xFF2E6DB4),
    Color(0xFF6B4E9B),
    Color(0xFFC45B28),
    Color(0xFF8B5E3C),
  ];

  static Color forIcon(IconData icon) {
    return palette[icon.codePoint.abs() % palette.length];
  }

  static Color at(int index) {
    if (palette.isEmpty) return Colors.grey;
    return palette[index.abs() % palette.length];
  }

  /// Even index → palette[0], odd index → palette[1], then cycles.
  static Color alternating(int index) {
    if (palette.isEmpty) return Colors.grey;
    final slot = index.abs() % 2;
    return palette[slot % palette.length];
  }

  static Icon icon(
    IconData data, {
    double size = 24,
    int? colorIndex,
  }) {
    final color = colorIndex != null ? alternating(colorIndex) : forIcon(data);
    return Icon(data, size: size, color: color);
  }

  static Color auto() {
  final index = DateTime.now().millisecondsSinceEpoch ~/ 3000;
  return palette[index % palette.length];
}
}
