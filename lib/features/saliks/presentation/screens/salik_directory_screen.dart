import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/form_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/salik_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/filter_bar.dart';
import '../widgets/salik_browse_segment_bar.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class SalikDirectoryScreen extends ConsumerWidget {
  const SalikDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final saliksAsync = ref.watch(saliksStreamProvider);
    final filtered = ref.watch(filteredSaliksProvider);
    final filterNotifier = ref.read(salikFilterProvider.notifier);
    final canCreate =
        session != null && AccessControl.canCreate(session.role);
    final canViewPending =
        session != null && AccessControl.canViewPending(session.role);
    final pendingCount =
        canViewPending ? ref.watch(pendingCountProvider) : 0;

    final canResolveDuplicates = session != null &&
        AccessControl.canResolveDuplicates(session.role);
    final duplicateCount = canResolveDuplicates
        ? ref.watch(duplicateSalikCountProvider)
        : 0;

    return AppScaffold(
      title: l10n.t('saliks'),
      actions: [
        if (canResolveDuplicates)
          IconButton(
            icon: duplicateCount > 0
                ? Badge(
                    label: Text('$duplicateCount'),
                    child: const Icon(Icons.copy_all_outlined),
                  )
                : const Icon(Icons.copy_all_outlined),
            tooltip: l10n.t('duplicate_data'),
            onPressed: () => context.push('/saliks/duplicates'),
          ),
        if (canViewPending)
          IconButton(
            icon: PendingSaliksBadge(
              count: pendingCount,
              child: const Icon(Icons.pending_actions),
            ),
            tooltip: AccessControl.isEditor(session.role)
                ? l10n.t('my_submissions')
                : l10n.t('pending_approvals'),
            onPressed: () => context.push('/saliks/pending'),
          ),
        if (canCreate)
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.t('add_salik'),
            onPressed: () =>
                context.go(addSalikRoute(from: FormReturnRoute.saliks)),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: SearchBar(
              hintText: l10n.t('search_placeholder'),
              leading: const Icon(Icons.search),
              onChanged: filterNotifier.setSearch,
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).cardColor,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const SalikBrowseSegmentBar(),
          const SizedBox(height: AppSpacing.sm),
          const FilterChips(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: saliksAsync.when(
              loading: () => const AppLoadingPage(),
              error: (e, _) => ErrorState(
                message: mapFirebaseError(e, l10n),
                onRetry: () => ref.invalidate(saliksStreamProvider),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return EmptyState(
                    message: l10n.t('empty_saliks'),
                    actionLabel: canCreate ? l10n.t('add_salik') : null,
                    onAction: canCreate
                        ? () => context.go(
                              addSalikRoute(from: FormReturnRoute.saliks),
                            )
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(saliksStreamProvider);
                    ref.invalidate(pendingSaliksStreamProvider);
                    ref.invalidate(pendingCountProvider);
                    ref.invalidate(citiesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final salik = filtered[index];
                      final city = ref
                              .watch(cityByIdProvider(salik.cityId))
                              .valueOrNull ??
                          findCity(salik.cityId);
                      return SalikListTile(
                        salik: salik,
                        cityName: city?.cityName ?? '',
                        statusBadge: salik.isPending
                            ? l10n.t('approval_pending')
                            : null,
                        onProfile: () =>
                            context.push('/saliks/profile/${salik.salikId}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () =>
                  context.go(addSalikRoute(from: FormReturnRoute.saliks)),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
