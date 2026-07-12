import 'package:flutter/material.dart';
import '../../features/saliks/domain/entities/salik.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/contact_launcher.dart';
import '../utils/icon_colors.dart';
import '../utils/salik_contact_preference.dart';
import '../utils/text_field_merge.dart';
import 'salik_avatar.dart';
import 'whatsapp_icon.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.fatherName,
    super.key,
    this.badge,
  });

  final String name;
  final String fatherName;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayName = name.trim();
    final displayFather = fatherName.trim();

    return Column(
      children: [
        if (badge != null) ...[
          badge!,
          const SizedBox(height: AppSpacing.sm),
        ],
        if (displayName.isNotEmpty)
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: textDirectionFor(displayName),
            style: AppTextStyles.forLocale(
              containsUrduScript(displayName),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (displayFather.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.t('father_name')}: $displayFather',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: textDirectionFor(displayFather),
            style: AppTextStyles.forLocale(
              containsUrduScript(displayFather),
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
    this.labelFontSize = 8,
    this.railWidth = 92,
  });

  final String mobileNumber;
  final String whatsappNumber;
  final double iconSize;
  final MainAxisAlignment mainAxisAlignment;
  final bool showLabels;
  final double labelFontSize;
  final double railWidth;

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
        labelFontSize: labelFontSize,
        width: railWidth,
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
          icon: Icons.phone_in_talk,
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

/// Top-right contact control for list cards — tap to pick action, icon reflects choice.
class SalikCardContactButton extends StatefulWidget {
  const SalikCardContactButton({
    required this.mobileNumber,
    required this.whatsappNumber,
    super.key,
    this.iconSize = 22,
  });

  final String mobileNumber;
  final String whatsappNumber;
  final double iconSize;

  @override
  State<SalikCardContactButton> createState() => _SalikCardContactButtonState();
}

class _SalikCardContactButtonState extends State<SalikCardContactButton> {
  SalikContactAction _preferred = SalikContactAction.call;

  @override
  void initState() {
    super.initState();
    _loadPreferred();
  }

  Future<void> _loadPreferred() async {
    final preferred = await SalikContactPreference.getPreferred();
    if (mounted) setState(() => _preferred = preferred);
  }

  String get _waNumber => phonesMatch(widget.mobileNumber, widget.whatsappNumber)
      ? widget.mobileNumber
      : widget.whatsappNumber;

  void _execute(SalikContactAction action) {
    switch (action) {
      case SalikContactAction.call:
        ContactLauncher.call(widget.mobileNumber);
      case SalikContactAction.sms:
        ContactLauncher.sms(widget.mobileNumber);
      case SalikContactAction.whatsappMessage:
        ContactLauncher.whatsappMessage(_waNumber);
      case SalikContactAction.whatsappCall:
        ContactLauncher.whatsappCall(_waNumber);
    }
  }

  Future<void> _showPicker() async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<SalikContactAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.t('contact'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ContactPickerTile(
              label: l10n.t('call'),
              icon: IconColors.icon(Icons.phone, colorIndex: 0),
              selected: _preferred == SalikContactAction.call,
              onTap: () => Navigator.pop(ctx, SalikContactAction.call),
            ),
            _ContactPickerTile(
              label: l10n.t('message'),
              icon: IconColors.icon(Icons.sms_outlined, colorIndex: 1),
              selected: _preferred == SalikContactAction.sms,
              onTap: () => Navigator.pop(ctx, SalikContactAction.sms),
            ),
            _ContactPickerTile(
              label: l10n.t('wa_message'),
              icon: const WhatsAppMessageIcon(size: 22),
              selected: _preferred == SalikContactAction.whatsappMessage,
              onTap: () =>
                  Navigator.pop(ctx, SalikContactAction.whatsappMessage),
            ),
            _ContactPickerTile(
              label: l10n.t('wa_call'),
              icon: const WhatsAppCallIcon(size: 22),
              selected: _preferred == SalikContactAction.whatsappCall,
              onTap: () => Navigator.pop(ctx, SalikContactAction.whatsappCall),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await SalikContactPreference.setPreferred(selected);
    setState(() => _preferred = selected);
    _execute(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showPicker,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: IconColors.icon(
            Icons.phone_in_talk,
            size: widget.iconSize,
            colorIndex: 0,
          ),
        ),
      ),
    );
  }
}

class _ContactPickerTile extends StatelessWidget {
  const _ContactPickerTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, size: 20) : null,
      onTap: onTap,
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
    this.labelFontSize = 8,
    this.width = 92,
  });

  final String mobileNumber;
  final String whatsappNumber;
  final double iconSize;
  final double labelFontSize;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waNumber =
        phonesMatch(mobileNumber, whatsappNumber) ? mobileNumber : whatsappNumber;
    final labelStyle = AppTextStyles.forLocale(
      false,
      fontSize: labelFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );

    final rail = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledContactAction(
                label: l10n.t('call'),
                labelStyle: labelStyle,
                icon: IconColors.icon(
                  Icons.phone_in_talk,
                  size: iconSize,
                  colorIndex: 0,
                ),
                onPressed: () => ContactLauncher.call(mobileNumber),
              ),
            ),
            Expanded(
              child: _LabeledContactAction(
                label: l10n.t('message'),
                labelStyle: labelStyle,
                icon: IconColors.icon(
                  Icons.sms_outlined,
                  size: iconSize,
                  colorIndex: 1,
                ),
                onPressed: () => ContactLauncher.sms(mobileNumber),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: _LabeledContactAction(
                label: l10n.t('wa_message'),
                labelStyle: labelStyle,
                icon: WhatsAppMessageIcon(size: iconSize),
                onPressed: () => ContactLauncher.whatsappMessage(waNumber),
              ),
            ),
            Expanded(
              child: _LabeledContactAction(
                label: l10n.t('wa_call'),
                labelStyle: labelStyle,
                icon: WhatsAppCallIcon(size: iconSize),
                onPressed: () => ContactLauncher.whatsappCall(waNumber),
              ),
            ),
          ],
        ),
      ],
    );

    if (!width.isFinite) {
      return rail;
    }

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(width: width, child: rail),
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
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: labelStyle,
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
    required this.onProfile,
    this.cityName = '',
    this.statusBadge,
    super.key,
  });

  final Salik salik;
  final String cityName;
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              40,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _SalikCardInfo(
                    salik: salik,
                    cityName: cityName,
                    onProfile: onProfile,
                  ),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _SalikCardBadges(badges: badges),
                ],
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: SalikCardContactButton(
              mobileNumber: salik.mobileNumber,
              whatsappNumber: salik.whatsappNumber,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalikCardInfo extends StatelessWidget {
  const _SalikCardInfo({
    required this.salik,
    required this.cityName,
    required this.onProfile,
  });

  final Salik salik;
  final String cityName;
  final VoidCallback onProfile;

  static const _lineStyle = TextStyle(fontSize: 13, height: 1.25);
  static final _mutedStyle = TextStyle(
    fontSize: 12,
    height: 1.25,
    color: Colors.grey.shade600,
  );

  @override
  Widget build(BuildContext context) {
    final displayName = salik.name.trim();
    final displayFather = salik.fatherName.trim();
    final displayCity = cityName.trim();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayName.isNotEmpty)
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.ltr,
                    style: _lineStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                if (displayFather.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    displayFather,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.ltr,
                    style: _mutedStyle,
                  ),
                ],
                if (salik.mobileNumber.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    salik.mobileNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.ltr,
                    style: _lineStyle.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
                if (displayCity.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    displayCity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.ltr,
                    style: _mutedStyle.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalikCardBadges extends StatelessWidget {
  const _SalikCardBadges({required this.badges});

  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: badges,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.forLocale(
                false,
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
