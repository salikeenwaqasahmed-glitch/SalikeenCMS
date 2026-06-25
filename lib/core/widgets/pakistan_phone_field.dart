import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../utils/icon_colors.dart';
import '../utils/pakistan_phone.dart';

class PakistanPhoneFormField extends StatelessWidget {
  const PakistanPhoneFormField({
    required this.controller,
    required this.labelText,
    this.validator,
    this.prefixIcon,
    this.prefix,
    this.colorIndex = 0,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? prefix;
  final int colorIndex;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.t('country_code'),
              isDense: true,
              helperText: PakistanPhone.defaultCountryIso,
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
            child: const Text(
              PakistanPhone.defaultCountryCode,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
              hintText: '0300-1234567',
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
            inputFormatters: [PakistanPhoneInputFormatter()],
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
