import 'package:flutter/material.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/domain/user_session.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/access_control.dart';

class UserScopeBanner extends StatelessWidget {
  const UserScopeBanner({
    required this.session,
    super.key,
    this.compact = false,
  });

  final UserSession session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAdmin = AccessControl.canViewAllGenders(session.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            l10n.t('your_access'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            RoleChip(role: session.role),
            GenderChip(gender: session.gender),
            if (isAdmin)
              _ScopeChip(
                label: l10n.t('scope_all_genders'),
                color: AppTheme.primaryColor,
              ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            isAdmin
                ? l10n.t('scope_all_genders')
                : session.gender == 'Female'
                    ? l10n.t('scope_female_only')
                    : l10n.t('scope_male_only'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

class RoleChip extends StatelessWidget {
  const RoleChip({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Color color;
    switch (role) {
      case UserRole.admin:
        color = AppTheme.primaryColor;
      case UserRole.approval:
        color = Colors.orange;
      case UserRole.editor:
      case UserRole.crudUser:
        color = Colors.teal;
    }
    return _ScopeChip(label: l10n.t(role.l10nKey()), color: color);
  }
}

class GenderChip extends StatelessWidget {
  const GenderChip({required this.gender, super.key});

  final String gender;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFemale = gender == 'Female';
    return _ScopeChip(
      label: isFemale ? l10n.t('female') : l10n.t('male'),
      color: isFemale ? Colors.purple : Colors.blue,
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
