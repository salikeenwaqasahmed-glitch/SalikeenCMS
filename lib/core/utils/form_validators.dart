import '../data/country_codes.dart';
import '../localization/app_localizations.dart';
import 'phone_number_utils.dart';

class FormValidators {
  static String? requiredField(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.t('required_field');
    }
    return null;
  }

  static String? phoneField(
    String? value,
    AppLocalizations l10n, {
    CountryDialCode country = kDefaultCountry,
  }) {
    final required = requiredField(value, l10n);
    if (required != null) return required;
    return PhoneNumberUtils.validationMessage(
      value!,
      l10n,
      country: country,
    );
  }

  static String? optionalPhone(
    String? value,
    AppLocalizations l10n, {
    CountryDialCode country = kDefaultCountry,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    return PhoneNumberUtils.validationMessage(
      value,
      l10n,
      country: country,
    );
  }

  static String? emailField(String? value, AppLocalizations l10n) {
    final required = requiredField(value, l10n);
    if (required != null) return required;
    final trimmed = value!.trim();
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return l10n.t('error_invalid_email');
    }
    return null;
  }

  static String? selectRequired(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.t('error_select_required');
    }
    return null;
  }
}
