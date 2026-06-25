import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SalikAvatar extends StatelessWidget {
  const SalikAvatar({
    required this.name,
    this.radius = 26,
    super.key,
  });

  final String name;
  final double radius;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final first = String.fromCharCode(trimmed.runes.first);
    return first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.accentGold,
      child: Text(
        _initial,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
