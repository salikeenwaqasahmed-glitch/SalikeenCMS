import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/text_field_merge.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/area.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

/// Opens modal bottom sheet for bazam / area / status / gender filters.
Future<void> showSalikFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const SalikFilterSheet(),
  );
}

class SalikFilterSheet extends ConsumerWidget {
  const SalikFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(salikFilterProvider);
    final notifier = ref.read(salikFilterProvider.notifier);
    final session = ref.watch(currentSessionProvider);
    final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
    final bazams = ref.watch(bazamsProvider).valueOrNull ?? kBazams;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final scopedAreas = filter.bazamId == 'all'
        ? areas
        : areas.where((a) => a.bazamId == filter.bazamId).toList();
    final areaValue = scopedAreas.any((a) => a.areaId == filter.areaId)
        ? filter.areaId
        : 'all';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  l10n.t('filters'),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (filter.activeAdvancedFilterCount > 0)
                TextButton(
                  onPressed: notifier.clearAdvancedFilters,
                  child: Text(l10n.t('clear_filters')),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SheetDropdown(
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
          _SheetDropdown(
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
            _SheetDropdown(
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
          _SheetDropdown(
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
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.t('ok')),
          ),
        ],
      ),
    );
  }
}

class _SheetDropdown extends StatelessWidget {
  const _SheetDropdown({
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
          key: ValueKey('$label-$safeValue'),
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

String _areaLabel(Area area, {required bool isUrdu}) {
  final label = localeBilingualLabel(area.areaName, isUrdu: isUrdu).trim();
  return label.isNotEmpty ? label : area.areaName.trim();
}
