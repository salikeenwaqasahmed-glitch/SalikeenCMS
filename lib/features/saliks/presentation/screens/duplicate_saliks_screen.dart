import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/text_field_merge.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/salik_widgets.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/salik_repository.dart';
import '../../domain/entities/duplicate_salik_reason.dart';
import '../../domain/entities/salik.dart';
import '../../domain/entities/salik_duplicate_group.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class DuplicateSaliksScreen extends ConsumerWidget {
  const DuplicateSaliksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final groupsAsync = ref.watch(duplicateSaliksStreamProvider);

    if (session == null || !AccessControl.canResolveDuplicates(session.role)) {
      return AppScaffold(
        title: l10n.t('duplicate_data'),
        showBackButton: true,
        onBack: () => context.go('/saliks'),
        body: EmptyState(message: l10n.t('no_access')),
      );
    }

    return AppScaffold(
      title: l10n.t('duplicate_data'),
      showBackButton: true,
      onBack: () => context.go('/saliks'),
      body: groupsAsync.when(
        loading: () => const AppLoadingPage(),
        error: (e, _) => ErrorState(
          message: mapFirebaseError(e, l10n),
          onRetry: () => ref.invalidate(duplicateSaliksStreamProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(message: l10n.t('no_duplicate_data'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(duplicateSaliksStreamProvider);
              ref.invalidate(saliksStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return _DuplicateGroupCard(
                  group: groups[index],
                  session: session,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DuplicateGroupCard extends ConsumerStatefulWidget {
  const _DuplicateGroupCard({
    required this.group,
    required this.session,
  });

  final SalikDuplicateGroup group;
  final UserSession session;

  @override
  ConsumerState<_DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends ConsumerState<_DuplicateGroupCard> {
  late String _keepId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _keepId = widget.group.saliks.first.salikId;
  }

  @override
  void didUpdateWidget(covariant _DuplicateGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.group.saliks.any((s) => s.salikId == _keepId)) {
      _keepId = widget.group.saliks.first.salikId;
    }
  }

  String _reasonLabel(AppLocalizations l10n, DuplicateSalikReason reason) {
    return switch (reason) {
      DuplicateSalikReason.mobile => l10n.t('duplicate_match_mobile'),
      DuplicateSalikReason.name => l10n.t('duplicate_match_person'),
    };
  }

  Future<void> _mergeGroup() async {
    final l10n = context.l10n;
    final removeIds = widget.group.saliks
        .map((s) => s.salikId)
        .where((id) => id != _keepId)
        .toList();
    if (removeIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('merge_duplicates')),
        content: Text(l10n.t('merge_duplicates_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('merge_duplicates')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(salikRepositoryProvider).mergeDuplicateSaliks(
            session: widget.session,
            keepSalikId: _keepId,
            removeSalikIds: removeIds,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('merge_success'))),
      );
      ref.invalidate(duplicateSaliksStreamProvider);
      ref.invalidate(saliksStreamProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapFirebaseError(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteOne(Salik salik) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('delete_confirm')),
        content: Text(l10n.t('delete_duplicate_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('delete_confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(salikRepositoryProvider).deleteSalik(
            salik.salikId,
            session: widget.session,
            duplicateCleanup: true,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('delete_success'))),
      );
      ref.invalidate(duplicateSaliksStreamProvider);
      ref.invalidate(saliksStreamProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapFirebaseError(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasons = widget.group.reasons
        .map((DuplicateSalikReason r) => _reasonLabel(l10n, r))
        .toSet()
        .join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              reasons,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              widget.group.label,
              maxLines: 2,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            AppText(
              l10n
                  .t('duplicate_group_count')
                  .replaceAll('{count}', '${widget.group.saliks.length}'),
              maxLines: 1,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.group.saliks.map((salik) {
              final area = ref.watch(areaByIdProvider(salik.areaId)).valueOrNull ??
                  findArea(salik.areaId);
              final locationLabel = area?.areaName ?? salik.address.trim();
              return Column(
                children: [
                  RadioListTile<String>(
                    value: salik.salikId,
                    groupValue: _keepId,
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _keepId = value);
                          },
                    title: AppText(l10n.t('keep_this_record'), maxLines: 1),
                    subtitle: AppText(
                      salik.name.trim(),
                      maxLines: 1,
                      textDirection: textDirectionFor(salik.name),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SalikListTile(
                          salik: salik,
                          locationLabel: locationLabel,
                          onProfile: () =>
                              context.push('/saliks/profile/${salik.salikId}'),
                          statusBadge: salik.isPending
                              ? l10n.t('approval_pending')
                              : null,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.t('delete_confirm'),
                        onPressed: _busy ? null : () => _deleteOne(salik),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            AppActionButton(
              loading: _busy,
              onPressed: widget.group.saliks.length < 2 || _busy
                  ? null
                  : _mergeGroup,
              child: AppText(l10n.t('merge_duplicates'), maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
