import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/text_field_merge.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../dashboard/presentation/widgets/stat_count_card.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

/// Lists areas belonging to a bazam; tap area opens filtered saliks directory.
class BazamAreasScreen extends ConsumerWidget {
  const BazamAreasScreen({required this.bazamId, super.key});

  final String bazamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bazamAsync = ref.watch(bazamByIdProvider(bazamId));
    final areas = ref.watch(areasForBazamProvider(bazamId));
    final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
    final allAreas = ref.watch(areasProvider).valueOrNull ?? kAreas;

    final title = bazamAsync.valueOrNull?.bazamName ??
        findBazam(bazamId)?.bazamName ??
        bazamId;

    final bazamSalikCount = saliks.where((s) {
      return resolveSalikBazamId(
            salikBazamId: s.bazamId,
            areaId: s.areaId,
            areas: allAreas,
          ) ==
          bazamId;
    }).length;

    // All card + area cards
    final itemCount = areas.length + 1;

    return AppScaffold(
      title: title,
      showBackButton: true,
      onBack: () => context.go('/'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SectionTitle(l10n.t('areas')),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return StatCountCard(
                  label: l10n.t('all'),
                  count: bazamSalikCount,
                  icon: Icons.groups,
                  colorIndex: 0,
                  onTap: () {
                    ref.read(salikFilterProvider.notifier).setBazam(bazamId);
                    context.go('/saliks');
                  },
                );
              }

              final area = areas[index - 1];
              final count =
                  saliks.where((s) => s.areaId == area.areaId).length;
              final isUrdu =
                  Localizations.localeOf(context).languageCode == 'ur';
              final label = localeBilingualLabel(
                area.areaName,
                isUrdu: isUrdu,
              ).trim();

              return StatCountCard(
                label: label.isNotEmpty ? label : area.areaName.trim(),
                count: count,
                icon: Icons.location_on,
                colorIndex: index,
                onTap: () {
                  final notifier = ref.read(salikFilterProvider.notifier);
                  notifier.setSegment(SalikBrowseSegment.area);
                  notifier.setArea(area.areaId);
                  context.go('/saliks');
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            l10n.t('bazam_areas_hint'),
            maxLines: 3,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
