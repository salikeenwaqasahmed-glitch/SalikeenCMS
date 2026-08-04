import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../dashboard/presentation/widgets/segment_pill_bar.dart';
import '../providers/salik_provider.dart';

/// Category segments only (All / Area / Nafi / Sahib). Location filters live in sheet.
class SalikBrowseSegmentBar extends ConsumerWidget {
  const SalikBrowseSegmentBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(salikFilterProvider);
    final notifier = ref.read(salikFilterProvider.notifier);

    final segmentLabels = [
      l10n.t('segment_all'),
      l10n.t('segment_area'),
      l10n.t('segment_nafi_asbat'),
      l10n.t('segment_sahib_mehfil'),
    ];
    final segmentIndex = SalikBrowseSegment.values.indexOf(filter.segment);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      child: SegmentPillBar(
        labels: segmentLabels,
        selectedIndex: segmentIndex,
        onSelected: (i) {
          notifier.setSegment(SalikBrowseSegment.values[i]);
        },
      ),
    );
  }
}
