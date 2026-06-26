import 'package:flutter/material.dart';

import '../data/country_codes.dart';
import '../localization/app_localizations.dart';
import '../utils/icon_colors.dart';
import '../utils/phone_number_utils.dart';
import 'country_code_picker.dart';

class PakistanPhoneFormField extends StatelessWidget {
  const PakistanPhoneFormField({
    required this.controller,
    required this.labelText,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.validator,
    this.prefixIcon,
    this.prefix,
    this.colorIndex = 0,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final CountryDialCode selectedCountry;
  final ValueChanged<CountryDialCode> onCountryChanged;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? prefix;
  final int colorIndex;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPk = PhoneNumberUtils.isPakistan(selectedCountry);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await showCountryCodePicker(
                context,
                selected: selectedCountry,
              );
              if (picked != null) onCountryChanged(picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.t('country_code'),
                isDense: true,
                helperText: selectedCountry.iso,
                helperStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCountry.dialCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: isPk ? '0300-1234567' : '1234567890',
              prefixIcon: prefix ??
                  (prefixIcon == null
                      ? null
                      : IconColors.icon(
                          prefixIcon!,
                          size: 22,
                          colorIndex: colorIndex,
                        )),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              InternationalPhoneInputFormatter(selectedCountry),
            ],
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Alias for the international phone field widget.
typedef InternationalPhoneFormField = PakistanPhoneFormField;
