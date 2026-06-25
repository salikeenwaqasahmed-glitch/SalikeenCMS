import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/icon_colors.dart';

class StatCountCard extends StatelessWidget {
  const StatCountCard({
    required this.label,
    required this.count,
    required this.icon,
    super.key,
    this.color,
    this.expanded = true,
    this.width = 108,
    this.onTap,
    this.colorIndex,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color? color;
  final int? colorIndex;
  final bool expanded;
  final double width;
  final VoidCallback? onTap;

  Color get _iconColor {
    if (color != null) return color!;
    if (colorIndex != null) return IconColors.at(colorIndex!);
    return IconColors.forIcon(icon);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconColor = _iconColor;
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$count',
                style: AppTextStyles.forLocale(
                  l10n.isUrdu,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    if (expanded) return Expanded(child: card);
    return SizedBox(width: width, child: card);
  }
}
