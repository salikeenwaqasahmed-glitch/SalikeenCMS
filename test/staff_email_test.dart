import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/core/auth/staff_email.dart';
import 'package:salik_management_system/core/localization/app_localizations.dart';

AppLocalizations _fakeL10n() => AppLocalizations(const Locale('en'));

void main() {
  group('composeStaffEmail', () {
    test('appends dev domain to local part', () {
      expect(composeStaffEmail('madmin'), 'madmin@dev.cms.com');
    });

    test('normalizes casing on local part', () {
      expect(composeStaffEmail('  MAdmin  '), 'madmin@dev.cms.com');
    });

    test('passes through full email when @ present', () {
      expect(
        composeStaffEmail('madmin@dev.cms.com'),
        'madmin@dev.cms.com',
      );
    });

    test('passes through prod email on dev build when typed by mistake', () {
      expect(composeStaffEmail('sarkar@cms.com'), 'sarkar@cms.com');
    });
  });

  group('staffEmailLocalPartValidator', () {
    test('accepts local part only', () {
      expect(
        staffEmailLocalPartValidator('madmin', _fakeL10n()),
        isNull,
      );
    });

    test('accepts full email pasted by mistake', () {
      expect(
        staffEmailLocalPartValidator('madmin@dev.cms.com', _fakeL10n()),
        isNull,
      );
    });

    test('rejects bare @', () {
      expect(
        staffEmailLocalPartValidator('madmin@', _fakeL10n()),
        isNotNull,
      );
    });
  });

  group('localPartFromStaffEmail', () {
    test('strips dev domain suffix', () {
      expect(
        localPartFromStaffEmail('madmin@dev.cms.com'),
        'madmin',
      );
    });

    test('returns full email when domain does not match', () {
      expect(
        localPartFromStaffEmail('legacy@example.com'),
        'legacy@example.com',
      );
    });
  });
}
