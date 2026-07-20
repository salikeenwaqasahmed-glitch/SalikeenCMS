import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/utils/submitter_display.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/salik_widgets.dart';
import '../../../../core/sync/sync_refresh.dart';
import '../../../../core/widgets/offline_cached_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/entities/salik.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final pendingAsync = ref.watch(pendingSaliksStreamProvider);
    final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
    final areaLookup = buildAreaLookup(areas);
    final isEditor =
        session != null && AccessControl.isEditor(session.role);
    final title =
        isEditor ? l10n.t('my_submissions') : l10n.t('pending_approvals');

    return AppScaffold(
      title: title,
      showBackButton: true,
      onBack: () => context.go('/saliks'),
      body: pendingAsync.when(
        loading: () => const AppLoadingPage(),
        error: (e, _) => ErrorState(
          message: mapFirebaseError(e, l10n),
          onRetry: () => ref.invalidate(pendingSaliksStreamProvider),
        ),
        data: (saliks) {
          if (saliks.isEmpty) {
            return EmptyState(
              message: isEditor
                  ? l10n.t('no_submissions')
                  : l10n.t('no_pending_approvals'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => pullToRefreshSync(ref, context: context),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: saliks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: OfflineCachedBanner(),
                  );
                }
                final salik = saliks[index - 1];
                final locationLabel =
                    salikLocationLabel(salik, areaLookup);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isEditor)
                      _PendingSubmitterLine(salik: salik),
                    SalikListTile(
                      salik: salik,
                      locationLabel: locationLabel,
                      onProfile: () =>
                          context.push('/saliks/profile/${salik.salikId}'),
                      statusBadge: _statusLabel(l10n, salik.approvalStatus),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  String? _statusLabel(dynamic l10n, ApprovalStatus status) {
    return switch (status) {
      ApprovalStatus.pending => l10n.t('approval_pending'),
      ApprovalStatus.rejected => l10n.t('approval_rejected'),
      ApprovalStatus.approved => null,
    };
  }
}

class _PendingSubmitterLine extends ConsumerWidget {
  const _PendingSubmitterLine({required this.salik});

  final Salik salik;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nameAsync = ref.watch(salikAddedByNameProvider(salik));

    return nameAsync.when(
      data: (name) {
        final display = resolveSubmitterLineName(name);
        if (display == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            l10n.t('submitted_by').replaceAll('{name}', display),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        child: AppLoader(size: AppLoaderSize.small),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
