import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/env_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/user_scope_banner.dart';
import '../../../../core/contacts/contact_import_actions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saliks/presentation/widgets/salik_import_export_actions.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final syncState = ref.watch(syncNowControllerProvider);

    ref.listen(syncNowControllerProvider, (prev, next) {
      if (prev?.isLoading == true && next.hasValue) {
        final result = next.value ?? const SyncNowResult(ok: false);
        final message = _syncSnackMessage(l10n, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    return AppScaffold(
      title: l10n.t('settings'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (session != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.accentGold,
                      child: Text(
                        session.name.isNotEmpty
                            ? session.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            session.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.forLocale(
                              false,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(session.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: AppSpacing.sm),
                          const EnvBadge(compact: true, showProject: true),
                          const SizedBox(height: AppSpacing.sm),
                          UserScopeBanner(session: session, compact: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(l10n.t('account')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(l10n.t('role')),
                  subtitle: AppText(
                    session != null ? l10n.t(session.role.l10nKey()) : '-',
                    maxLines: 1,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wc),
                  title: Text(l10n.t('gender')),
                  subtitle: AppText(
                    session?.gender == 'Female'
                        ? l10n.t('female')
                        : l10n.t('male'),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(l10n.t('preferences')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: Text(l10n.t('dark_mode')),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(l10n.t('sync_now')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    isOnline ? l10n.t('sync_now') : l10n.t('offline_mode'),
                  ),
                  subtitle: pendingCount > 0
                      ? Text(
                          l10n.t('pending_sync_count')
                              .replaceAll('{count}', '$pendingCount'),
                        )
                      : null,
                ),
                if (isOnline && pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: FilledButton.icon(
                      onPressed: syncState.isLoading
                          ? null
                          : () => ref
                              .read(syncNowControllerProvider.notifier)
                              .syncNow(),
                      icon: syncState.isLoading
                          ? const AppLoader(
                              size: AppLoaderSize.small,
                              color: Colors.white,
                            )
                          : const Icon(Icons.sync),
                      label: Text(l10n.t('sync_now')),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(l10n.t('import_export')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.import_contacts),
                  title: Text(l10n.t('import_contacts')),
                  onTap: session == null
                      ? null
                      : () => showContactImportActions(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(l10n.t('export_saliks')),
                  onTap: session == null
                      ? null
                      : () => exportSaliksFromSettings(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _LogoutButton(),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Salikeen CMS v1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerStatefulWidget {
  const _LogoutButton();

  @override
  ConsumerState<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends ConsumerState<_LogoutButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FilledButton.icon(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await ref.read(authControllerProvider.notifier).signOut();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.shade700,
      ),
      icon: _loading
          ? const AppLoader(
              size: AppLoaderSize.small,
              color: Colors.white,
            )
          : const Icon(Icons.logout),
      label: Text(l10n.t('logout')),
    );
  }
}

String _syncSnackMessage(AppLocalizations l10n, SyncNowResult result) {
  if (result.ok) {
    return l10n.t('sync_success');
  }
  final err = result.error;
  if (err != null) {
    if (err.contains('permission-denied')) {
      return '${l10n.t('error_permission_denied')} ${l10n.t('sync_permission_hint')}';
    }
    return mapFirebaseError(err, l10n);
  }
  return l10n.t('sync_failed');
}
