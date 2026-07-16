import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../dashboard/presentation/widgets/segment_pill_bar.dart';
import '../../domain/entities/area.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class SalikBrowseSegmentBar extends ConsumerWidget {
  const SalikBrowseSegmentBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(salikFilterProvider);
    final notifier = ref.read(salikFilterProvider.notifier);
    final areasAsync = ref.watch(areasProvider);

    final segmentLabels = [
      l10n.t('segment_all'),
      l10n.t('segment_area'),
      l10n.t('segment_nafi_asbat'),
      l10n.t('segment_sahib_mehfil'),
    ];
    final segmentIndex = SalikBrowseSegment.values.indexOf(filter.segment);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentPillBar(
            labels: segmentLabels,
            selectedIndex: segmentIndex,
            onSelected: (i) {
              notifier.setSegment(SalikBrowseSegment.values[i]);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChip(
              label: AppText(l10n.t('inactive'), maxLines: 1),
              selected: filter.status == 'inactive',
              onSelected: (selected) {
                notifier.setStatus(selected ? 'inactive' : 'all');
              },
            ),
          ),
          if (filter.segment == SalikBrowseSegment.area) ...[
            const SizedBox(height: AppSpacing.sm),
            areasAsync.when(
              loading: () => _loadingPills(),
              error: (_, __) => _buildAreaPills(
                ref,
                l10n,
                kAreas,
                filter.areaId,
              ),
              data: (areas) => _buildAreaPills(
                ref,
                l10n,
                areas,
                filter.areaId,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _loadingPills() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: AppLoader(size: AppLoaderSize.small),
      ),
    );
  }

  Widget _buildAreaPills(
    WidgetRef ref,
    AppLocalizations l10n,
    List<Area> areas,
    String selectedAreaId,
  ) {
    final labels = <String>[
      l10n.t('all_areas'),
      ...areas.map((area) => area.areaName),
    ];
    final values = ['all', ...areas.map((area) => area.areaId)];
    final selectedIndex =
        values.indexOf(selectedAreaId).clamp(0, values.length - 1);

    return SegmentPillBar(
      labels: labels,
      selectedIndex: selectedIndex,
      onSelected: (i) {
        ref.read(salikFilterProvider.notifier).setArea(values[i]);
      },
    );
  }
}
