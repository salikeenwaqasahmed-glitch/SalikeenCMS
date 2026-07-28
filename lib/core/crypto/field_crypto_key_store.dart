import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/user_role.dart';
import '../../features/auth/domain/user_session.dart';
import '../network/connectivity_service.dart';
import 'field_crypto.dart';

final fieldCryptoKeyStoreProvider = Provider<FieldCryptoKeyStore>((ref) {
  return FieldCryptoKeyStore(
    const FlutterSecureStorage(),
    FirebaseFirestore.instance,
    ref.watch(connectivityServiceProvider),
  );
});

/// Shared org AES key: secure storage + Firestore `meta/fieldCrypto`.
/// Also mirrors to `users/{uid}/private/fieldKey` for the creating user.
class FieldCryptoKeyStore {
  FieldCryptoKeyStore(this._secure, this._firestore, this._connectivity);

  static const _storageKey = 'salik_field_crypto_key_v1';
  static const _metaDoc = 'fieldCrypto';

  final FlutterSecureStorage _secure;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;

  FieldCrypto? _cached;

  FieldCrypto? get current => _cached;

  Future<FieldCrypto?> ensureKey(UserSession? session) async {
    if (_cached != null) return _cached;

    final local = await _secure.read(key: _storageKey);
    if (local != null && local.isNotEmpty) {
      try {
        _cached = FieldCrypto.fromBase64Key(local);
        return _cached;
      } catch (e) {
        debugPrint('Invalid local field crypto key: $e');
      }
    }

    if (!await _connectivity.isOnline || session == null) {
      return null;
    }

    try {
      final metaSnap =
          await _firestore.collection('meta').doc(_metaDoc).get();
      if (metaSnap.exists) {
        final keyBase64 = metaSnap.data()?['keyBase64'] as String?;
        if (keyBase64 != null && keyBase64.isNotEmpty) {
          await _secure.write(key: _storageKey, value: keyBase64);
          _cached = FieldCrypto.fromBase64Key(keyBase64);
          return _cached;
        }
      }

      // Per-user private backup (plan path).
      if (!session.uid.startsWith('local-')) {
        final privateSnap = await _firestore
            .collection('users')
            .doc(session.uid)
            .collection('private')
            .doc('fieldKey')
            .get();
        final keyBase64 = privateSnap.data()?['keyBase64'] as String?;
        if (keyBase64 != null && keyBase64.isNotEmpty) {
          await _secure.write(key: _storageKey, value: keyBase64);
          _cached = FieldCrypto.fromBase64Key(keyBase64);
          // Promote to shared meta if missing and admin.
          if (session.role == UserRole.admin) {
            await _uploadSharedKey(keyBase64);
          }
          return _cached;
        }
      }

      // First online admin creates the shared org key.
      if (session.role == UserRole.admin && !session.uid.startsWith('local-')) {
        final keyBase64 = FieldCrypto.generateKeyBase64();
        await _uploadSharedKey(keyBase64);
        await _firestore
            .collection('users')
            .doc(session.uid)
            .collection('private')
            .doc('fieldKey')
            .set({
          'keyBase64': keyBase64,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _secure.write(key: _storageKey, value: keyBase64);
        _cached = FieldCrypto.fromBase64Key(keyBase64);
        return _cached;
      }
    } catch (e, st) {
      debugPrint('Field crypto key bootstrap failed: $e\n$st');
    }

    return null;
  }

  Future<void> _uploadSharedKey(String keyBase64) async {
    await _firestore.collection('meta').doc(_metaDoc).set({
      'keyBase64': keyBase64,
      'algorithm': 'AES-256-GCM',
      'version': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearLocal() async {
    _cached = null;
    await _secure.delete(key: _storageKey);
  }
}
