import 'package:flutter/material.dart';

/// Merge legacy paired EN/UR fields into one display/storage value.
String mergeLegacyBilingual({String primary = '', String secondary = ''}) {
  final a = primary.trim();
  final b = secondary.trim();
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  if (a == b) return a;
  return '$a / $b';
}

/// Split merged `English / Urdu` label into separate parts.
({String english, String urdu}) splitBilingualLabel(String value) {
  final parts = value
      .split('/')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return (english: '', urdu: '');
  }
  if (parts.length == 1) {
    if (containsUrduScript(parts.first)) {
      return (english: '', urdu: parts.first);
    }
    return (english: parts.first, urdu: '');
  }
  return (english: parts.first, urdu: parts.last);
}

/// Preferred locale label from merged bilingual text.
String localeBilingualLabel(String value, {required bool isUrdu}) {
  final split = splitBilingualLabel(value);
  if (isUrdu) {
    return split.urdu.isNotEmpty ? split.urdu : split.english;
  }
  return split.english.isNotEmpty ? split.english : split.urdu;
}

String readUnifiedText(
  Map<String, dynamic> map, {
  required String key,
  String legacyPrimaryKey = '',
  String legacySecondaryKey = '',
}) {
  final direct = map[key] as String?;
  if (direct != null && direct.trim().isNotEmpty) {
    return direct.trim();
  }
  if (legacyPrimaryKey.isEmpty && legacySecondaryKey.isEmpty) {
    return '';
  }
  return mergeLegacyBilingual(
    primary: map[legacyPrimaryKey] as String? ?? '',
    secondary: map[legacySecondaryKey] as String? ?? '',
  );
}

final _urduScriptPattern = RegExp(r'[\u0600-\u06FF]');

bool containsUrduScript(String value) => _urduScriptPattern.hasMatch(value);

TextDirection textDirectionFor(String value) =>
    containsUrduScript(value) ? TextDirection.rtl : TextDirection.ltr;
