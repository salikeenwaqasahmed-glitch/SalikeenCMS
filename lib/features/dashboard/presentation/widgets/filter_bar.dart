import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/text_field_merge.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/utils/access_control.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saliks/domain/entities/area.dart';
import '../../../saliks/domain/entities/bazam.dart';
import '../../../saliks/presentation/providers/area_provider.dart';
import '../../../saliks/presentation/providers/salik_provider.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(salikFilterProvider);
    final session = ref.watch(currentSessionProvider);
    final notifier = ref.read(salikFilterProvider.notifier);
    final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
    final bazams = ref.watch(bazamsProvider).valueOrNull ?? kBazams;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    final scopedAreas = filter.bazamId == 'all'
        ? areas
        : areas.where((a) => a.bazamId == filter.bazamId).toList();

    final areaValue = scopedAreas.any((a) => a.areaId == filter.areaId)
        ? filter.areaId
        : 'all';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterDropdown(
              label: l10n.t('bazam'),
              value: filter.bazamId,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: AppText.dropdownItem(l10n.t('all_bazams')),
                ),
                ...bazams.map(
                  (bazam) => DropdownMenuItem(
                    value: bazam.bazamId,
                    child: AppText.dropdownItem(bazam.bazamName),
                  ),
                ),
              ],
              onChanged: notifier.setBazam,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FilterDropdown(
              label: l10n.t('area'),
              value: areaValue,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: AppText.dropdownItem(l10n.t('all_areas')),
                ),
                ...scopedAreas.map(
                  (area) => DropdownMenuItem(
                    value: area.areaId,
                    child: AppText.dropdownItem(
                      _areaLabel(area, isUrdu: isUrdu),
                    ),
                  ),
                ),
              ],
              onChanged: notifier.setArea,
            ),
            if (session != null &&
                AccessControl.canViewAllGenders(session.role)) ...[
              const SizedBox(height: AppSpacing.sm),
              _FilterDropdown(
                label: l10n.t('gender'),
                value: filter.genderId,
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: AppText.dropdownItem(l10n.t('all')),
                  ),
                  DropdownMenuItem(
                    value: 'Male',
                    child: AppText.dropdownItem(l10n.t('male')),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: AppText.dropdownItem(l10n.t('female')),
                  ),
                ],
                onChanged: notifier.setGender,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _FilterDropdown(
              label: l10n.t('active'),
              value: filter.status,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: AppText.dropdownItem(l10n.t('all')),
                ),
                DropdownMenuItem(
                  value: 'active',
                  child: AppText.dropdownItem(l10n.t('active')),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: AppText.dropdownItem(l10n.t('inactive')),
                ),
              ],
              onChanged: notifier.setStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final itemValues = items.map((i) => i.value).whereType<String>().toSet();
    final safeValue = itemValues.contains(value) ? value : 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          label,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key, this.showClearAll = true});

  final bool showClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(salikFilterProvider);
    final notifier = ref.read(salikFilterProvider.notifier);
    final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
    final bazams = ref.watch(bazamsProvider).valueOrNull ?? kBazams;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    Widget chip(String label, VoidCallback onDeleted) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
        child: InputChip(
          label: AppText(label, maxLines: 1),
          onDeleted: onDeleted,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      );
    }

    final chips = <Widget>[
      if (filter.bazamId != 'all')
        chip(
          _bazamChipLabel(bazamId: filter.bazamId, bazams: bazams),
          () => notifier.setBazam('all'),
        ),
      if (filter.areaId != 'all')
        chip(
          _areaChipLabel(
            areaId: filter.areaId,
            areas: areas,
            isUrdu: isUrdu,
          ),
          () => notifier.setArea('all'),
        ),
      if (filter.genderId != 'all')
        chip(
          filter.genderId == 'Male' ? l10n.t('male') : l10n.t('female'),
          () => notifier.setGender('all'),
        ),
      if (filter.status != 'all')
        chip(
          filter.status == 'active' ? l10n.t('active') : l10n.t('inactive'),
          () => notifier.setStatus('all'),
        ),
      if (showClearAll && filter.activeAdvancedFilterCount > 0)
        TextButton(
          onPressed: notifier.clearAdvancedFilters,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(l10n.t('clear_filters')),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }
}

String _areaLabel(Area area, {required bool isUrdu}) {
  final label = localeBilingualLabel(area.areaName, isUrdu: isUrdu).trim();
  return label.isNotEmpty ? label : area.areaName.trim();
}

String _areaChipLabel({
  required String areaId,
  required List<Area> areas,
  required bool isUrdu,
}) {
  final area = findAreaInList(areaId, areas);
  if (area == null) return areaId;
  return _areaLabel(area, isUrdu: isUrdu);
}

String _bazamChipLabel({
  required String bazamId,
  required List<Bazam> bazams,
}) {
  final bazam = findBazamInList(bazamId, bazams);
  if (bazam == null) return bazamId;
  final name = bazam.bazamName.trim();
  return name.isNotEmpty ? name : bazamId;
}
