import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// Client-side AES-256-GCM field encryption for Firestore PII.
///
/// Ciphertext format: `enc:v1:` + base64(nonce[12] + cipher+tag).
/// Legacy plaintext (no prefix) passes through decrypt unchanged.
class FieldCrypto {
  FieldCrypto(this._keyBytes);

  static const prefix = 'enc:v1:';
  static const _nonceLength = 12;
  static const keyLength = 32;

  final Uint8List _keyBytes;

  factory FieldCrypto.fromBase64Key(String keyBase64) {
    final bytes = base64Decode(keyBase64);
    if (bytes.length != keyLength) {
      throw ArgumentError('Field crypto key must be $keyLength bytes');
    }
    return FieldCrypto(Uint8List.fromList(bytes));
  }

  static String generateKeyBase64() {
    return base64Encode(SecureRandom(keyLength).bytes);
  }

  static bool isEncrypted(String? value) {
    if (value == null) return false;
    return value.startsWith(prefix);
  }

  String? encryptField(String? plain) {
    if (plain == null) return null;
    if (plain.isEmpty) return plain;
    if (isEncrypted(plain)) return plain;

    final key = Key(_keyBytes);
    final iv = IV.fromSecureRandom(_nonceLength);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    final packed = Uint8List(iv.bytes.length + encrypted.bytes.length)
      ..setRange(0, iv.bytes.length, iv.bytes)
      ..setRange(iv.bytes.length, iv.bytes.length + encrypted.bytes.length,
          encrypted.bytes);
    return '$prefix${base64Encode(packed)}';
  }

  String? decryptField(String? value) {
    if (value == null) return null;
    if (value.isEmpty) return value;
    if (!isEncrypted(value)) return value;

    try {
      final packed = base64Decode(value.substring(prefix.length));
      if (packed.length <= _nonceLength) return value;

      final iv = IV(Uint8List.fromList(packed.sublist(0, _nonceLength)));
      final cipherBytes =
          Uint8List.fromList(packed.sublist(_nonceLength));
      final key = Key(_keyBytes);
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      return encrypter.decrypt(Encrypted(cipherBytes), iv: iv);
    } catch (_) {
      // Wrong key or corrupt ciphertext — return as-is for graceful degrade.
      return value;
    }
  }

  static const piiKeys = <String>{
    'name',
    'fatherName',
    'mobileNumber',
    'whatsappNumber',
    'address',
    'referenceName',
    'referenceMobile',
    'notes',
  };

  Map<String, dynamic> encryptSalikMap(Map<String, dynamic> map) {
    final out = Map<String, dynamic>.from(map);
    for (final key in piiKeys) {
      final value = out[key];
      if (value is String) {
        out[key] = encryptField(value);
      }
    }
    return out;
  }

  Map<String, dynamic> decryptSalikMap(Map<String, dynamic> map) {
    final out = Map<String, dynamic>.from(map);
    for (final key in piiKeys) {
      final value = out[key];
      if (value is String) {
        out[key] = decryptField(value);
      }
    }
    return out;
  }

  SalikPiiBundle encryptSalikPii({
    required String name,
    required String fatherName,
    required String mobileNumber,
    required String whatsappNumber,
    required String address,
    required String referenceName,
    required String referenceMobile,
    String? notes,
  }) {
    return SalikPiiBundle(
      name: encryptField(name) ?? '',
      fatherName: encryptField(fatherName) ?? '',
      mobileNumber: encryptField(mobileNumber) ?? '',
      whatsappNumber: encryptField(whatsappNumber) ?? '',
      address: encryptField(address) ?? '',
      referenceName: encryptField(referenceName) ?? '',
      referenceMobile: encryptField(referenceMobile) ?? '',
      notes: encryptField(notes),
    );
  }
}

class SalikPiiBundle {
  const SalikPiiBundle({
    required this.name,
    required this.fatherName,
    required this.mobileNumber,
    required this.whatsappNumber,
    required this.address,
    required this.referenceName,
    required this.referenceMobile,
    this.notes,
  });

  final String name;
  final String fatherName;
  final String mobileNumber;
  final String whatsappNumber;
  final String address;
  final String referenceName;
  final String referenceMobile;
  final String? notes;
}
