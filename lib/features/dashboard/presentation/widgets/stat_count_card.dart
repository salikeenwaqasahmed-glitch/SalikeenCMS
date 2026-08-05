import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/icon_colors.dart';
import '../../../../core/widgets/app_text.dart';

class StatCountCard extends StatelessWidget {
  const StatCountCard({
    required this.label,
    required this.count,
    required this.icon,
    super.key,
    this.color,
    this.expanded = true,
    this.width,
    this.labelMaxLines = 2,
    this.labelFontSize = 11,
    this.onTap,
    this.colorIndex,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color? color;
  final int? colorIndex;

  /// When true, wraps in [Expanded] for Row layouts.
  final bool expanded;

  /// Fixed width for horizontal strips. Null = fill parent (e.g. GridView).
  final double? width;
  final int labelMaxLines;
  final double labelFontSize;
  final VoidCallback? onTap;

  Color get _iconColor {
    if (color != null) return color!;
    if (colorIndex != null) return IconColors.at(colorIndex!);
    return IconColors.forIcon(icon);
  }

  static const TextHeightBehavior _tightLabelHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  TextStyle _labelStyle({required bool compact}) {
    return TextStyle(
      fontSize: labelFontSize,
      height: compact ? 1.12 : 1.15,
      color: Colors.grey.shade600,
      fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
    );
  }

  Widget _buildLabel({required bool compact}) {
    final lines = kIsWeb ? labelMaxLines.clamp(1, 2) : labelMaxLines;
    final style = _labelStyle(compact: compact);

    if (kIsWeb) {
      return Text(
        label,
        textAlign: TextAlign.center,
        maxLines: lines,
        overflow: TextOverflow.clip,
        style: style,
        textHeightBehavior: _tightLabelHeight,
      );
    }

    return AppText(
      label,
      textAlign: TextAlign.center,
      maxLines: lines,
      style: style,
      textHeightBehavior: _tightLabelHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor;
    final compact = !expanded;
    final vPad = compact ? AppSpacing.sm : AppSpacing.md;
    final iconSize = compact ? 20.0 : 22.0;
    final countSize = compact ? 20.0 : 22.0;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: vPad,
          ),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              SizedBox(height: compact ? 2 : AppSpacing.xs),
              AppFitText(
                '$count',
                style: AppTextStyles.forLocale(
                  false,
                  fontSize: countSize,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 2),
              if (compact)
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildLabel(compact: true),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: _buildLabel(compact: false),
                ),
            ],
          ),
        ),
      ),
    );

    if (expanded) return Expanded(child: card);
    if (width != null) {
      return SizedBox(width: width, height: double.infinity, child: card);
    }
    // Fill GridView / other tight parents — never Expanded outside Flex.
    return card;
  }
}
