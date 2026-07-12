import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/utils/access_control.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saliks/domain/entities/city.dart';
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
    final cities = ref.watch(citiesProvider).valueOrNull ?? kCities;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterDropdown(
              label: l10n.t('city'),
              value: filter.cityId,
              items: [
                DropdownMenuItem(value: 'all', child: AppText.dropdownItem(l10n.t('all'))),
                ...cities.map(
                  (c) => DropdownMenuItem(
                    value: c.cityId,
                    child: AppText.dropdownItem(c.cityName),
                  ),
                ),
              ],
              onChanged: notifier.setCity,
            ),
            if (session != null &&
                AccessControl.canViewAllGenders(session.role)) ...[
              const SizedBox(height: AppSpacing.sm),
              _FilterDropdown(
                label: l10n.t('gender'),
                value: filter.genderId,
                items: [
                  DropdownMenuItem(value: 'all', child: AppText.dropdownItem(l10n.t('all'))),
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
                DropdownMenuItem(value: 'all', child: AppText.dropdownItem(l10n.t('all'))),
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
          initialValue: value,
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
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(salikFilterProvider);
    final notifier = ref.read(salikFilterProvider.notifier);
    final cities = ref.watch(citiesProvider).valueOrNull ?? kCities;

    final chips = <Widget>[
      if (filter.cityId != 'all')
        Chip(
          label: AppText(
            _cityChipLabel(
              cityId: filter.cityId,
              cities: cities,
            ),
            maxLines: 1,
          ),
          onDeleted: () => notifier.setCity('all'),
        ),
      if (filter.genderId != 'all')
        Chip(
          label: AppText(
            filter.genderId == 'Male' ? l10n.t('male') : l10n.t('female'),
            maxLines: 1,
          ),
          onDeleted: () => notifier.setGender('all'),
        ),
      if (filter.status != 'all')
        Chip(
          label: AppText(
            filter.status == 'active'
                ? l10n.t('active')
                : l10n.t('inactive'),
            maxLines: 1,
          ),
          onDeleted: () => notifier.setStatus('all'),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      child: Row(children: chips),
    );
  }
}

String _cityChipLabel({
  required String cityId,
  required List<City> cities,
}) {
  final city = findCityInList(cityId, cities);
  if (city == null) return cityId;
  final label = city.cityName.trim();
  return label.isNotEmpty ? label : cityId;
}
