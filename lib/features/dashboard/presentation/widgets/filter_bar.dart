import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/saved_bilingual_text.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saliks/domain/entities/area.dart';
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
    final areas = filter.cityId == 'all'
        ? <Area>[]
        : (ref.watch(areasByCityProvider(filter.cityId)).valueOrNull ??
            areasForCity(filter.cityId));

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
                DropdownMenuItem(value: 'all', child: Text(l10n.t('all'))),
                ...cities.map(
                  (c) => DropdownMenuItem(
                    value: c.cityId,
                    child: Text(
                      savedCityLabel(
                        cityName: c.cityName,
                        cityNameUrdu: c.cityNameUrdu,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: notifier.setCity,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FilterDropdown(
              label: l10n.t('area'),
              value: filter.areaId,
              items: [
                DropdownMenuItem(value: 'all', child: Text(l10n.t('all'))),
                ...areas.map(
                  (a) => DropdownMenuItem(
                    value: a.areaId,
                    child: Text(
                      savedAreaLabel(
                        areaName: a.areaName,
                        areaNameUrdu: a.areaNameUrdu,
                      ),
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
                  DropdownMenuItem(value: 'all', child: Text(l10n.t('all'))),
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text(l10n.t('male')),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text(l10n.t('female')),
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
                DropdownMenuItem(value: 'all', child: Text(l10n.t('all'))),
                DropdownMenuItem(
                  value: 'active',
                  child: Text(l10n.t('active')),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text(l10n.t('inactive')),
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
        Text(
          label,
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
    final areas = filter.cityId == 'all'
        ? <Area>[]
        : (ref.watch(areasByCityProvider(filter.cityId)).valueOrNull ??
            areasForCity(filter.cityId));

    final chips = <Widget>[
      if (filter.cityId != 'all')
        Chip(
          label: Text(
            _cityChipLabel(
              cityId: filter.cityId,
              cities: cities,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () => notifier.setCity('all'),
        ),
      if (filter.areaId != 'all')
        Chip(
          label: Text(
            _areaChipLabel(
              filter: filter,
              areas: areas,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () => notifier.setArea('all'),
        ),
      if (filter.genderId != 'all')
        Chip(
          label: Text(
            filter.genderId == 'Male' ? l10n.t('male') : l10n.t('female'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () => notifier.setGender('all'),
        ),
      if (filter.status != 'all')
        Chip(
          label: Text(
            filter.status == 'active'
                ? l10n.t('active')
                : l10n.t('inactive'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  final label = savedCityLabel(
    cityName: city.cityName,
    cityNameUrdu: city.cityNameUrdu,
  );
  return label.isNotEmpty ? label : cityId;
}

String _areaChipLabel({
  required SalikFilter filter,
  required List<Area> areas,
}) {
  final area =
      findAreaInList(filter.areaId, areas) ?? findArea(filter.areaId);
  if (area == null) return filter.areaId;
  final label = savedAreaLabel(
    areaName: area.areaName,
    areaNameUrdu: area.areaNameUrdu,
  );
  return label.isNotEmpty ? label : filter.areaId;
}
