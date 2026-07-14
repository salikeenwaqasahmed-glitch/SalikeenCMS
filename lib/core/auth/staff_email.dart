import '../config/app_config.dart';
import '../localization/app_localizations.dart';
import 'local_auth_store.dart';

/// Composes a full staff email from local part or passes through full addresses.
String composeStaffEmail(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  final normalized = LocalAuthStore.normalizeEmail(trimmed);
  if (normalized.contains('@')) return normalized;

  return '$normalized${AppConfig.staffEmailDomain}';
}

/// Strips env domain suffix for display in the login local-part field.
String localPartFromStaffEmail(String email) {
  final normalized = LocalAuthStore.normalizeEmail(email);
  if (normalized.isEmpty) return '';

  final domain = AppConfig.staffEmailDomain;
  if (normalized.endsWith(domain)) {
    return normalized.substring(0, normalized.length - domain.length);
  }

  return normalized;
}

String? staffEmailLocalPartValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.t('required_field');
  }
  final trimmed = value.trim();
  if (trimmed.contains(' ')) {
    return l10n.t('error_invalid_email_local');
  }
  if (trimmed.contains('@')) {
    // User pasted full email by mistake — accept if minimally valid.
    if (trimmed.startsWith('@') ||
        trimmed.endsWith('@') ||
        !trimmed.contains('.')) {
      return l10n.t('error_invalid_email');
    }
    return null;
  }
  return null;
}

String loginEmailHint() =>
    AppConfig.isProd ? 'sarkar' : 'madmin';
