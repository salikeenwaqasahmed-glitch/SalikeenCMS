import 'package:flutter/material.dart';

import '../data/country_codes.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';

Future<CountryDialCode?> showCountryCodePicker(
  BuildContext context, {
  CountryDialCode selected = kDefaultCountry,
}) {
  return showModalBottomSheet<CountryDialCode>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => CountryCodePickerSheet(selected: selected),
  );
}

class CountryCodePickerSheet extends StatefulWidget {
  const CountryCodePickerSheet({
    required this.selected,
    super.key,
  });

  final CountryDialCode selected;

  @override
  State<CountryCodePickerSheet> createState() => _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<CountryCodePickerSheet> {
  final _searchController = TextEditingController();
  late List<CountryDialCode> _filtered = kCountryDialCodes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _filtered = filterCountries(value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.t('select_country'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.t('search_country'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final isSelected = country.iso == widget.selected.iso;
                  return ListTile(
                    selected: isSelected,
                    title: Text(country.name),
                    subtitle: Text(country.iso),
                    trailing: Text(
                      country.dialCode,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => Navigator.pop(context, country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
