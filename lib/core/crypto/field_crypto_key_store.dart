import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/user_session.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import 'field_crypto.dart';

final fieldCryptoKeyStoreProvider = Provider<FieldCryptoKeyStore>((ref) {
  return FieldCryptoKeyStore(
    ref.watch(appDatabaseProvider),
    const FlutterSecureStorage(),
  );
});

/// AES field-crypto key: Drift `local_app_kv` only (never Firestore).
/// Prefers [AppConfig.fieldCryptoKeyBase64] when set (shared org key).
class FieldCryptoKeyStore {
  FieldCryptoKeyStore(this._db, this._secure);

  static const kvKey = 'field_crypto_key_v1';
  static const _legacySecureKey = 'salik_field_crypto_key_v1';

  final AppDatabase _db;
  final FlutterSecureStorage _secure;

  FieldCrypto? _cached;

  FieldCrypto? get current => _cached;

  Future<FieldCrypto?> ensureKey(UserSession? session) async {
    if (_cached != null) return _cached;

    final fromDefine = AppConfig.fieldCryptoKeyBase64.trim();
    if (fromDefine.isNotEmpty) {
      final existing = await _db.getKv(kvKey);
      if (existing != fromDefine) {
        await _db.setKv(kvKey, fromDefine);
      }
      return _cacheFromBase64(fromDefine);
    }

    final fromDrift = await _db.getKv(kvKey);
    if (fromDrift != null && fromDrift.isNotEmpty) {
      return _cacheFromBase64(fromDrift);
    }

    // One-shot migrate from older FlutterSecureStorage installs.
    try {
      final legacy = await _secure.read(key: _legacySecureKey);
      if (legacy != null && legacy.isNotEmpty) {
        await _db.setKv(kvKey, legacy);
        await _secure.delete(key: _legacySecureKey);
        return _cacheFromBase64(legacy);
      }
    } catch (e) {
      debugPrint('Field crypto secure-storage migrate failed: $e');
    }

    // Dev fallback only when no compile-time key.
    final generated = FieldCrypto.generateKeyBase64();
    await _db.setKv(kvKey, generated);
    debugPrint(
      'Field crypto: generated local key (set FIELD_CRYPTO_KEY_BASE64 '
      'for shared key across installs/.NET)',
    );
    return _cacheFromBase64(generated);
  }

  FieldCrypto? _cacheFromBase64(String keyBase64) {
    try {
      _cached = FieldCrypto.fromBase64Key(keyBase64);
      return _cached;
    } catch (e) {
      debugPrint('Invalid field crypto key: $e');
      return null;
    }
  }

  Future<void> clearLocal() async {
    _cached = null;
    await _db.deleteKv(kvKey);
    try {
      await _secure.delete(key: _legacySecureKey);
    } catch (_) {}
  }
}
