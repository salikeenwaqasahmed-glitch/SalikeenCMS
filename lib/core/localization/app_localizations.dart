import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'translations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  String t(String key) {
    return kTranslations[locale.languageCode]?[key] ??
        kTranslations['en']![key] ??
        key;
  }

  bool get isUrdu => locale.languageCode == 'ur';

  TextDirection get textDirection =>
      isUrdu ? TextDirection.rtl : TextDirection.ltr;

  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations(locale);
  }
}

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return AppLocalizations(const Locale('en'));
});

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
