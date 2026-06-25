import 'package:flutter/material.dart';
import '../../features/saliks/domain/entities/salik.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/contact_launcher.dart';
import '../utils/icon_colors.dart';
import 'salik_avatar.dart';
import 'whatsapp_icon.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.subtitle,
    super.key,
    this.badge,
  });

  final String name;
  final String subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        if (badge != null) ...[
          badge!,
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.forLocale(
            l10n.isUrdu,
            fontSize: l10n.isUrdu ? 24 : 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.forLocale(
            l10n.isUrdu,
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

bool phonesMatch(String a, String b) => ContactLauncher.sameNumber(a, b);

class SalikContactActions extends StatelessWidget {
  const SalikContactActions({
    required this.mobileNumber,
    required this.whatsappNumber,
    super.key,
    this.iconSize = 20,
    this.mainAxisAlignment = MainAxisAlignment.end,
    this.showLabels = false,
  });

  final String mobileNumber;
  final String whatsappNumber;
  final double iconSize;
  final MainAxisAlignment mainAxisAlignment;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waNumber =
        phonesMatch(mobileNumber, whatsappNumber) ? mobileNumber : whatsappNumber;

    if (showLabels) {
      return SalikCardContactRail(
        mobileNumber: mobileNumber,
        whatsappNumber: whatsappNumber,
        iconSize: iconSize,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
        _ContactActionButton(
          tooltip: l10n.t('call'),
          icon: Icons.phone,
          colorIndex: 0,
          iconSize: iconSize,
          onPressed: () => ContactLauncher.call(mobileNumber),
        ),
        _ContactActionButton(
          tooltip: l10n.t('message'),
          icon: Icons.sms_outlined,
          colorIndex: 1,
          iconSize: iconSize,
          onPressed: () => ContactLauncher.sms(mobileNumber),
        ),
        _ContactActionButton(
          tooltip: l10n.t('whatsapp'),
          iconWidget: WhatsAppMessageIcon(size: iconSize),
          colorIndex: 2,
          iconSize: iconSize,
          onPressed: () => ContactLauncher.whatsappMessage(waNumber),
        ),
        _ContactActionButton(
          tooltip: l10n.t('whatsapp_call'),
          iconWidget: WhatsAppCallIcon(size: iconSize),
          colorIndex: 3,
          iconSize: iconSize,
          onPressed: () => ContactLauncher.whatsappCall(waNumber),
        ),
      ],
      ),
    );
  }
}

/// Right-side contact rail for salik cards — mobile call/SMS + WhatsApp actions.
class SalikCardContactRail extends StatelessWidget {
  const SalikCardContactRail({
    required this.mobileNumber,
    required this.whatsappNumber,
    super.key,
    this.iconSize = 14,
  });

  final String mobileNumber;
  final String whatsappNumber;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waNumber =
        phonesMatch(mobileNumber, whatsappNumber) ? mobileNumber : whatsappNumber;
    final labelStyle = AppTextStyles.forLocale(
      l10n.isUrdu,
      fontSize: 8,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledContactAction(
          label: l10n.t('call'),
          labelStyle: labelStyle,
          icon: IconColors.icon(
            Icons.phone,
            size: iconSize,
            colorIndex: 0,
          ),
          onPressed: () => ContactLauncher.call(mobileNumber),
        ),
        _LabeledContactAction(
          label: l10n.t('message'),
          labelStyle: labelStyle,
          icon: IconColors.icon(
            Icons.sms_outlined,
            size: iconSize,
            colorIndex: 1,
          ),
          onPressed: () => ContactLauncher.sms(mobileNumber),
        ),
        Container(
          width: 1,
          height: iconSize + 14,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: Colors.grey.shade300,
        ),
        _LabeledContactAction(
          label: l10n.t('wa_message'),
          labelStyle: labelStyle,
          icon: WhatsAppMessageIcon(size: iconSize),
          onPressed: () => ContactLauncher.whatsappMessage(waNumber),
        ),
        _LabeledContactAction(
          label: l10n.t('wa_call'),
          labelStyle: labelStyle,
          icon: WhatsAppCallIcon(size: iconSize),
          onPressed: () => ContactLauncher.whatsappCall(waNumber),
        ),
      ],
      ),
    );
  }
}

class _SalikCardBadge extends StatelessWidget {
  const _SalikCardBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LabeledContactAction extends StatelessWidget {
  const _LabeledContactAction({
    required this.label,
    required this.labelStyle,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final TextStyle labelStyle;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(
              width: 38,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.tooltip,
    this.icon,
    this.iconWidget,
    required this.colorIndex,
    required this.iconSize,
    required this.onPressed,
  }) : assert(icon != null || iconWidget != null);

  final String tooltip;
  final IconData? icon;
  final Widget? iconWidget;
  final int colorIndex;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = iconWidget ??
        IconColors.icon(
          icon!,
          size: iconSize,
          colorIndex: colorIndex,
        );

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: tooltip,
      icon: child,
      onPressed: onPressed,
    );
  }
}

class SalikListTile extends StatelessWidget {
  const SalikListTile({
    required this.salik,
    required this.displayName,
    required this.displayFather,
    required this.areaName,
    required this.onProfile,
    this.statusBadge,
    super.key,
  });

  final Salik salik;
  final String displayName;
  final String displayFather;
  final String areaName;
  final VoidCallback onProfile;
  final String? statusBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badges = <Widget>[];
    if (!salik.isActive) {
      badges.add(_SalikCardBadge(
        label: l10n.t('inactive'),
        background: Colors.red.shade50,
        foreground: Colors.red,
      ));
    } else if (salik.isSahibEMehfil) {
      badges.add(_SalikCardBadge(
        label: l10n.t('sahib_e_mehfil'),
        background: Colors.amber.shade50,
        foreground: Colors.amber.shade900,
      ));
    }
    if (statusBadge != null) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 4));
      badges.add(_SalikCardBadge(
        label: statusBadge!,
        background: Colors.orange.shade50,
        foreground: Colors.orange.shade900,
      ));
    }

    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final info = _SalikCardInfo(
              l10n: l10n,
              displayName: displayName,
              displayFather: displayFather,
              mobileNumber: salik.mobileNumber,
              areaName: areaName,
              onProfile: onProfile,
            );
            final trailing = _SalikCardTrailing(
              badges: badges,
              mobileNumber: salik.mobileNumber,
              whatsappNumber: salik.whatsappNumber,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: info),
                const SizedBox(width: AppSpacing.xs),
                Flexible(child: trailing),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SalikCardInfo extends StatelessWidget {
  const _SalikCardInfo({
    required this.l10n,
    required this.displayName,
    required this.displayFather,
    required this.mobileNumber,
    required this.areaName,
    required this.onProfile,
  });

  final AppLocalizations l10n;
  final String displayName;
  final String displayFather;
  final String mobileNumber;
  final String areaName;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onProfile,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SalikAvatar(name: displayName, radius: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.forLocale(
                    l10n.isUrdu,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.t('father_name')}: $displayFather',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  mobileNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (areaName.isNotEmpty)
                  Text(
                    areaName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalikCardTrailing extends StatelessWidget {
  const _SalikCardTrailing({
    required this.badges,
    required this.mobileNumber,
    required this.whatsappNumber,
  });

  final List<Widget> badges;
  final String mobileNumber;
  final String whatsappNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badges.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: badges,
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.grey.shade300,
          ),
        ],
        SalikCardContactRail(
          mobileNumber: mobileNumber,
          whatsappNumber: whatsappNumber,
        ),
      ],
    );
  }
}

class InfoGroupCard extends StatelessWidget {
  const InfoGroupCard({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.forLocale(
                l10n.isUrdu,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.leading,
    this.onTap,
    this.colorIndex = 0,
  }) : assert(icon != null || leading != null);

  final IconData? icon;
  final Widget? leading;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final rowLeading = leading ??
        Icon(
          icon!,
          size: 20,
          color: IconColors.alternating(colorIndex),
        );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: rowLeading,
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing:
          onTap != null ? const Icon(Icons.chevron_right, size: 18) : null,
      onTap: onTap,
    );
  }
}

/// Red count badge when pending saliks exist.
class PendingSaliksBadge extends StatelessWidget {
  const PendingSaliksBadge({
    required this.count,
    required this.child,
    super.key,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: Colors.red,
      textColor: Colors.white,
      child: child,
    );
  }
}
