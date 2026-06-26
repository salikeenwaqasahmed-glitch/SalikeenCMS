import 'package:flutter/services.dart';

import '../data/country_codes.dart';
import '../localization/app_localizations.dart';

class ParsedPhone {
  const ParsedPhone({
    required this.country,
    required this.nationalDigits,
  });

  final CountryDialCode country;
  final String nationalDigits;
}

/// Country-aware phone formatting, E.164 storage, and validation.
class PhoneNumberUtils {
  PhoneNumberUtils._();

  static const pkLocalDigitLength = 11;

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static bool isPakistan(CountryDialCode country) => country.iso == 'PK';

  static ParsedPhone parseStored(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) {
      return const ParsedPhone(country: kDefaultCountry, nationalDigits: '');
    }

    if (trimmed.startsWith('+')) {
      final digits = digitsOnly(trimmed);
      final country = findCountryByDialCode(digits);
      if (country != null) {
        final national = digits.substring(country.dialDigits.length);
        return ParsedPhone(
          country: country,
          nationalDigits: _normalizeNationalForCountry(country, national),
        );
      }
    }

    var digits = digitsOnly(trimmed);
    if (digits.startsWith('92') && digits.length >= 12) {
      final national = '0${digits.substring(2)}';
      return ParsedPhone(
        country: kDefaultCountry,
        nationalDigits: _normalizePkLocalDigits(national),
      );
    }

    if (digits.startsWith('03') ||
        (digits.length == 10 && digits.startsWith('3'))) {
      return ParsedPhone(
        country: kDefaultCountry,
        nationalDigits: _normalizePkLocalDigits(digits),
      );
    }

    if (digits.length >= 10) {
      final country = findCountryByDialCode(digits);
      if (country != null && country.iso != 'PK') {
        final national = digits.substring(country.dialDigits.length);
        return ParsedPhone(country: country, nationalDigits: national);
      }
    }

    return ParsedPhone(
      country: kDefaultCountry,
      nationalDigits: _normalizePkLocalDigits(digits),
    );
  }

  static String formatNationalDisplay(
    CountryDialCode country,
    String nationalDigits,
  ) {
    final digits = digitsOnly(nationalDigits);
    if (digits.isEmpty) return '';
    if (isPakistan(country)) {
      return _formatPkLocalDigits(_normalizePkLocalDigits(digits));
    }
    return digits;
  }

  static String toStored(CountryDialCode country, String nationalInput) {
    final national = digitsOnly(nationalInput);
    if (national.isEmpty) return '';

    if (isPakistan(country)) {
      final local = _normalizePkLocalDigits(national);
      if (local.isEmpty) return '';
      final e164National = local.startsWith('0') ? local.substring(1) : local;
      return '+${country.dialDigits}$e164National';
    }

    final trimmedNational =
        national.startsWith('0') ? national.replaceFirst(RegExp(r'^0+'), '') : national;
    return '+${country.dialDigits}$trimmedNational';
  }

  static String toDialableDigits(String stored) {
    final parsed = parseStored(stored);
    if (parsed.nationalDigits.isEmpty) return '';

    if (isPakistan(parsed.country)) {
      final local = _normalizePkLocalDigits(parsed.nationalDigits);
      final e164National = local.startsWith('0') ? local.substring(1) : local;
      return '${parsed.country.dialDigits}$e164National';
    }

    return '${parsed.country.dialDigits}${parsed.nationalDigits}';
  }

  static String formatFromStored(String stored) {
    final parsed = parseStored(stored);
    return formatNationalDisplay(parsed.country, parsed.nationalDigits);
  }

  static bool isValid(CountryDialCode country, String nationalInput) {
    final digits = digitsOnly(nationalInput);
    if (digits.isEmpty) return false;

    if (isPakistan(country)) {
      final local = _normalizePkLocalDigits(digits);
      if (local.length != pkLocalDigitLength) return false;
      return local.startsWith('03');
    }

    final normalized =
        digits.startsWith('0') ? digits.replaceFirst(RegExp(r'^0+'), '') : digits;
    return normalized.length >= 7 && normalized.length <= 15;
  }

  static String? validationMessage(
    String value,
    AppLocalizations l10n, {
    CountryDialCode? country,
  }) {
    final resolvedCountry = country ?? kDefaultCountry;
    if (!isValid(resolvedCountry, value)) {
      return l10n.t('error_invalid_phone');
    }
    return null;
  }

  static String _normalizeNationalForCountry(
    CountryDialCode country,
    String national,
  ) {
    if (isPakistan(country)) {
      return _normalizePkLocalDigits(national);
    }
    return digitsOnly(national);
  }

  static String _normalizePkLocalDigits(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length == 10 && digits.startsWith('3')) {
      return '0$digits';
    }
    return digits;
  }

  static String _formatPkLocalDigits(String digits) {
    final normalized = _normalizePkLocalDigits(digits);
    if (normalized.isEmpty) return '';

    final limited = normalized.length > pkLocalDigitLength
        ? normalized.substring(0, pkLocalDigitLength)
        : normalized;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 4) buffer.write('-');
      buffer.write(limited[i]);
    }
    return buffer.toString();
  }
}

class PakistanPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PhoneNumberUtils.digitsOnly(newValue.text);
    final normalized = PhoneNumberUtils._normalizePkLocalDigits(digits);
    final limited = normalized.length > PhoneNumberUtils.pkLocalDigitLength
        ? normalized.substring(0, PhoneNumberUtils.pkLocalDigitLength)
        : normalized;
    final formatted = PhoneNumberUtils._formatPkLocalDigits(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class InternationalPhoneInputFormatter extends TextInputFormatter {
  InternationalPhoneInputFormatter(this.country);

  final CountryDialCode country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (PhoneNumberUtils.isPakistan(country)) {
      return PakistanPhoneInputFormatter().formatEditUpdate(oldValue, newValue);
    }

    final digits = PhoneNumberUtils.digitsOnly(newValue.text);
    final limited = digits.length > 15 ? digits.substring(0, 15) : digits;
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}

// Backward-compatible aliases used across the app.
class PakistanPhone {
  PakistanPhone._();

  static const defaultCountryCode = '+92';
  static const defaultCountryIso = 'PK';
  static const localDigitLength = PhoneNumberUtils.pkLocalDigitLength;

  static String digitsOnly(String value) => PhoneNumberUtils.digitsOnly(value);

  static String formatFromStored(String stored) =>
      PhoneNumberUtils.formatFromStored(stored);

  static String toStored(String localMasked) =>
      PhoneNumberUtils.toStored(kDefaultCountry, localMasked);

  static String normalizeLocalDigits(String digits) =>
      PhoneNumberUtils._normalizePkLocalDigits(digits);

  static String formatLocalDigits(String digits) =>
      PhoneNumberUtils._formatPkLocalDigits(digits);

  static bool isValidLocal(String value) =>
      PhoneNumberUtils.isValid(kDefaultCountry, value);

  static String? validationMessage(String value, AppLocalizations l10n) =>
      PhoneNumberUtils.validationMessage(value, l10n, country: kDefaultCountry);
}
