import '../localization/app_localizations.dart';
import 'pakistan_phone.dart';

class FormValidators {
  static String? requiredField(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.t('required_field');
    }
    return null;
  }

  static String? phoneField(String? value, AppLocalizations l10n) {
    final required = requiredField(value, l10n);
    if (required != null) return required;
    return PakistanPhone.validationMessage(value!, l10n);
  }

  static String? optionalPhone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return null;
    return PakistanPhone.validationMessage(value, l10n);
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
