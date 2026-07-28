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
import '../../../../core/sync/sync_refresh.dart';
import '../../../../core/widgets/offline_cached_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/filter_bar.dart';
import '../widgets/salik_browse_segment_bar.dart';
import '../../domain/entities/salik.dart';
import '../widgets/salik_import_export_actions.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class SalikDirectoryScreen extends ConsumerStatefulWidget {
  const SalikDirectoryScreen({super.key});

  @override
  ConsumerState<SalikDirectoryScreen> createState() =>
      _SalikDirectoryScreenState();
}

class _SalikDirectoryScreenState extends ConsumerState<SalikDirectoryScreen> {
  bool _selecting = false;
  final Set<String> _selected = {};

  void _enterSelectMode() {
    final filtered = ref.read(sortedFilteredSaliksProvider);
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('export_empty'))),
      );
      return;
    }
    setState(() {
      _selecting = true;
      _selected.clear();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleAll(List<Salik> filtered) {
    setState(() {
      if (_selected.length == filtered.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(filtered.map((s) => s.salikId));
      }
    });
  }

  Future<void> _continueMessaging() async {
    final filtered = ref.read(sortedFilteredSaliksProvider);
    final picked =
        filtered.where((s) => _selected.contains(s.salikId)).toList();
    if (picked.isEmpty) return;
    await continueMessageWithSelected(context, picked);
    if (!mounted) return;
    _exitSelectMode();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final saliksAsync = ref.watch(saliksStreamProvider);
    final filtered = ref.watch(sortedFilteredSaliksProvider);
    final paged = ref.watch(pagedSaliksProvider);
    final page = ref.watch(salikListPageProvider);
    final pageCount = ref.watch(salikListPageCountProvider);
    final filterNotifier = ref.read(salikFilterProvider.notifier);
    final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
    final areaLookup = buildAreaLookup(areas);
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

    final title = _selecting
        ? '${l10n.t('select_contacts')} (${_selected.length})'
        : l10n.t('saliks');

    return AppScaffold(
      title: title,
      actions: [
        if (_selecting) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: l10n.t('select_all'),
            onPressed: () => _toggleAll(filtered),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.t('cancel'),
            onPressed: _exitSelectMode,
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: l10n.t('message_saliks'),
            onPressed: _enterSelectMode,
          ),
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
          const OfflineCachedBanner(),
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
                  onRefresh: () => pullToRefreshSync(ref, context: context),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: paged.length + (pageCount > 1 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == paged.length) {
                        return _SalikPageControls(
                          page: page,
                          pageCount: pageCount,
                          onPrev: page > 0
                              ? () => ref
                                  .read(salikListPageProvider.notifier)
                                  .state = page - 1
                              : null,
                          onNext: page < pageCount - 1
                              ? () => ref
                                  .read(salikListPageProvider.notifier)
                                  .state = page + 1
                              : null,
                        );
                      }
                      final salik = paged[index];
                      final locationLabel =
                          salikLocationLabel(salik, areaLookup);
                      return SalikListTile(
                        salik: salik,
                        locationLabel: locationLabel,
                        statusBadge: salik.isPending
                            ? l10n.t('approval_pending')
                            : null,
                        selected: _selecting
                            ? _selected.contains(salik.salikId)
                            : null,
                        onSelectedChanged: _selecting
                            ? (checked) {
                                setState(() {
                                  if (checked) {
                                    _selected.add(salik.salikId);
                                  } else {
                                    _selected.remove(salik.salikId);
                                  }
                                });
                              }
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
          if (_selecting)
            SafeArea(
              top: false,
              child: Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: FilledButton.icon(
                    onPressed:
                        _selected.isEmpty ? null : _continueMessaging,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      '${l10n.t('next_step')} (${_selected.length})',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!_selecting && canCreate)
          ? FloatingActionButton(
              onPressed: () =>
                  context.go(addSalikRoute(from: FormReturnRoute.saliks)),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _SalikPageControls extends StatelessWidget {
  const _SalikPageControls({
    required this.page,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = l10n
        .t('page_of')
        .replaceAll('{current}', '${page + 1}')
        .replaceAll('{total}', '$pageCount');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: onPrev,
            child: Text(l10n.t('prev_page')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(label),
          ),
          TextButton(
            onPressed: onNext,
            child: Text(l10n.t('next_page')),
          ),
        ],
      ),
    );
  }
}
