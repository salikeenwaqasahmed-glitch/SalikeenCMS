import 'package:flutter/services.dart';

import '../localization/app_localizations.dart';

/// Pakistan (+92) mobile formatting, masking, and validation.
class PakistanPhone {
  PakistanPhone._();

  static const defaultCountryCode = '+92';
  static const defaultCountryIso = 'PK';
  static const localDigitLength = 11;

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  /// Normalizes stored/synced values into local `03XX-XXXXXXX` form.
  static String formatFromStored(String stored) {
    var digits = digitsOnly(stored);
    if (digits.isEmpty) return '';

    if (digits.startsWith('92') && digits.length >= 12) {
      digits = '0${digits.substring(2)}';
    } else if (digits.length == 10 && digits.startsWith('3')) {
      digits = '0$digits';
    }

    return formatLocalDigits(digits);
  }

  /// Saves national masked number for DB/display (`0300-1234567`).
  static String toStored(String localMasked) {
    final digits = normalizeLocalDigits(digitsOnly(localMasked));
    if (digits.isEmpty) return '';
    return formatLocalDigits(digits);
  }

  static String normalizeLocalDigits(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length == 10 && digits.startsWith('3')) {
      return '0$digits';
    }
    return digits;
  }

  static String formatLocalDigits(String digits) {
    final normalized = normalizeLocalDigits(digits);
    if (normalized.isEmpty) return '';

    final limited = normalized.length > localDigitLength
        ? normalized.substring(0, localDigitLength)
        : normalized;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 4) buffer.write('-');
      buffer.write(limited[i]);
    }
    return buffer.toString();
  }

  static bool isValidLocal(String value) {
    final digits = normalizeLocalDigits(digitsOnly(value));
    if (digits.length != localDigitLength) return false;
    if (!digits.startsWith('03')) return false;
    return true;
  }

  static String? validationMessage(String value, AppLocalizations l10n) {
    if (!isValidLocal(value)) {
      return l10n.t('error_invalid_phone');
    }
    return null;
  }
}

class PakistanPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PakistanPhone.digitsOnly(newValue.text);
    final normalized = PakistanPhone.normalizeLocalDigits(digits);
    final limited = normalized.length > PakistanPhone.localDigitLength
        ? normalized.substring(0, PakistanPhone.localDigitLength)
        : normalized;
    final formatted = PakistanPhone.formatLocalDigits(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
