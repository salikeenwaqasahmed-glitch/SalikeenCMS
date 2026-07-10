import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bounded [Text] with ellipsis + web-safe height behavior for tight layouts.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.textDirection,
    this.softWrap = true,
    this.textHeightBehavior,
  });

  static const TextHeightBehavior _webHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextHeightBehavior? textHeightBehavior;

  /// Single-line label for dropdowns, chips, and menus.
  static Widget dropdownItem(String label, {TextStyle? style}) {
    return AppText(label, style: style, maxLines: 1);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedOverflow = kIsWeb && overflow == TextOverflow.ellipsis
        ? TextOverflow.fade
        : overflow;

    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: resolvedOverflow,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      textHeightBehavior: textHeightBehavior ?? (kIsWeb ? _webHeight : null),
    );
  }
}

/// Shrinks text to fit narrow stat cards and badges.
class AppFitText extends StatelessWidget {
  const AppFitText(
    this.data, {
    super.key,
    this.style,
    this.alignment = Alignment.center,
  });

  final String data;
  final TextStyle? style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: AppText(
        data,
        style: style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
