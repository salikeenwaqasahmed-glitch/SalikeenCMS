import 'package:flutter_test/flutter_test.dart';

import 'package:salik_management_system/core/crypto/field_crypto.dart';
import 'package:salik_management_system/features/saliks/domain/entities/approval_status.dart';
import 'package:salik_management_system/features/saliks/domain/entities/salik.dart';
import 'package:salik_management_system/features/saliks/presentation/providers/salik_provider.dart';

Salik _salik({
  required String id,
  required String name,
  String fatherName = '',
  String mobile = '',
  String reference = '',
  String address = '',
  bool pending = false,
}) {
  return Salik(
    salikId: id,
    name: name,
    fatherName: fatherName,
    mobileNumber: mobile,
    whatsappNumber: mobile,
    areaId: 'a1',
    address: address,
    genderId: 'Male',
    bazamId: '',
    khanqahId: '',
    salikCategoryId: '',
    dateOfBaith: '2024-01-01',
    referenceName: reference,
    referenceMobile: '',
    isNafiAsbat: false,
    isSahibEMehfil: false,
    profilePicture: '',
    createdDate: '2024-01-01',
    modifiedDate: '2024-01-01',
    isActive: true,
    approvalStatus: pending
        ? ApprovalStatus.pending
        : ApprovalStatus.approved,
  );
}

void main() {
  group('applySalikFilters search ranking', () {
    test('name matches appear before reference matches', () {
      final saliks = [
        _salik(id: '1', name: 'Other', reference: 'Ali'),
        _salik(id: '2', name: 'Ali Khan', reference: 'Z'),
        _salik(id: '3', name: 'Bob', mobile: '03001234567', reference: ''),
        _salik(id: '4', name: 'Carl', address: 'Ali street'),
      ];

      final filtered = applySalikFilters(
        saliks,
        const SalikFilter(search: 'Ali'),
      );

      expect(filtered.map((s) => s.salikId).toList(), ['2', '1', '4']);
    });

    test('empty search returns locale-sorted list', () {
      final saliks = [
        _salik(id: '1', name: 'Zain'),
        _salik(id: '2', name: 'Ali'),
        _salik(id: '3', name: 'Bilal'),
      ];
      final filtered = applySalikFilters(saliks, const SalikFilter());
      expect(filtered.map((s) => s.name).toList(), ['Ali', 'Bilal', 'Zain']);
    });
  });

  group('pageSaliks', () {
    test('slices 20 per page', () {
      final saliks = List.generate(
        45,
        (i) => _salik(id: '$i', name: 'S$i'),
      );
      expect(pageSaliks(saliks, 0).length, 20);
      expect(pageSaliks(saliks, 1).length, 20);
      expect(pageSaliks(saliks, 2).length, 5);
      expect(pageSaliks(saliks, 3), isEmpty);
      expect(salikPageCount(45), 3);
      expect(salikPageCount(0), 1);
    });
  });

  group('FieldCrypto', () {
    test('round-trips plaintext', () {
      final crypto = FieldCrypto.fromBase64Key(FieldCrypto.generateKeyBase64());
      const plain = 'علی خان';
      final cipher = crypto.encryptField(plain)!;
      expect(FieldCrypto.isEncrypted(cipher), isTrue);
      expect(crypto.decryptField(cipher), plain);
    });

    test('legacy plaintext passes through decrypt', () {
      final crypto = FieldCrypto.fromBase64Key(FieldCrypto.generateKeyBase64());
      expect(crypto.decryptField('plain name'), 'plain name');
    });

    test('encryptSalikMap encrypts PII keys only', () {
      final crypto = FieldCrypto.fromBase64Key(FieldCrypto.generateKeyBase64());
      final encrypted = crypto.encryptSalikMap({
        'name': 'Ali',
        'genderId': 'Male',
        'areaId': 'area-1',
        'mobileNumber': '03001234567',
      });
      expect(FieldCrypto.isEncrypted(encrypted['name'] as String), isTrue);
      expect(encrypted['genderId'], 'Male');
      expect(encrypted['areaId'], 'area-1');
      expect(FieldCrypto.isEncrypted(encrypted['mobileNumber'] as String), isTrue);

      final decrypted = crypto.decryptSalikMap(encrypted);
      expect(decrypted['name'], 'Ali');
      expect(decrypted['mobileNumber'], '03001234567');
    });

    test('wrong key returns ciphertext gracefully', () {
      final a = FieldCrypto.fromBase64Key(FieldCrypto.generateKeyBase64());
      final b = FieldCrypto.fromBase64Key(FieldCrypto.generateKeyBase64());
      final cipher = a.encryptField('secret')!;
      final result = b.decryptField(cipher);
      expect(result, cipher);
    });
  });
}
