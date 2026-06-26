import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/core/data/country_codes.dart';
import 'package:salik_management_system/core/utils/phone_number_utils.dart';

void main() {
  group('PhoneNumberUtils.parseStored', () {
    test('legacy PK local number', () {
      final parsed = PhoneNumberUtils.parseStored('0300-1234567');
      expect(parsed.country.iso, 'PK');
      expect(parsed.nationalDigits, '03001234567');
    });

    test('legacy PK with 92 prefix', () {
      final parsed = PhoneNumberUtils.parseStored('923001234567');
      expect(parsed.country.iso, 'PK');
      expect(parsed.nationalDigits, '03001234567');
    });

    test('E.164 PK number', () {
      final parsed = PhoneNumberUtils.parseStored('+923001234567');
      expect(parsed.country.iso, 'PK');
      expect(parsed.nationalDigits, '03001234567');
    });

    test('E.164 US number', () {
      final parsed = PhoneNumberUtils.parseStored('+14155552671');
      expect(parsed.country.iso, 'US');
      expect(parsed.nationalDigits, '4155552671');
    });
  });

  group('PhoneNumberUtils.toStored', () {
    test('PK round trip', () {
      final stored = PhoneNumberUtils.toStored(kDefaultCountry, '0300-1234567');
      expect(stored, '+923001234567');
    });

    test('UAE number', () {
      const uae = CountryDialCode(iso: 'AE', name: 'UAE', dialCode: '+971');
      final stored = PhoneNumberUtils.toStored(uae, '501234567');
      expect(stored, '+971501234567');
    });
  });

  group('PhoneNumberUtils validation', () {
    test('valid PK number', () {
      expect(
        PhoneNumberUtils.isValid(kDefaultCountry, '0300-1234567'),
        isTrue,
      );
    });

    test('invalid PK number', () {
      expect(
        PhoneNumberUtils.isValid(kDefaultCountry, '0300-123'),
        isFalse,
      );
    });
  });

  group('PhoneNumberUtils.toDialableDigits', () {
    test('legacy PK to international digits', () {
      expect(
        PhoneNumberUtils.toDialableDigits('0300-1234567'),
        '923001234567',
      );
    });

    test('E.164 stays dialable', () {
      expect(
        PhoneNumberUtils.toDialableDigits('+14155552671'),
        '14155552671',
      );
    });
  });
}
