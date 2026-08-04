import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/user_role.dart';
import '../../features/auth/domain/user_session.dart';
import '../database/app_database.dart';

class OfflineWrongPasswordException implements Exception {
  const OfflineWrongPasswordException();
}

/// Offline login attempted for an account that has never signed in online
/// on this device (no local Drift user / password hash).
class NoLocalUserOfflineException implements Exception {
  const NoLocalUserOfflineException();
}

final localAuthStoreProvider = Provider<LocalAuthStore>((ref) {
  return LocalAuthStore(ref.watch(appDatabaseProvider));
});

class LocalAuthStore {
  LocalAuthStore(this._db);

  final AppDatabase _db;

  static const _saltKey = 'device_password_salt';
  static const _activeUidKey = 'active_offline_uid';
  static const _lastEmailKey = 'last_login_email';
  static const _lastPasswordKey = 'last_login_password';

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String> _getOrCreateSalt() async {
    final prefs = await _prefs;
    var salt = prefs.getString(_saltKey);
    if (salt == null || salt.isEmpty) {
      salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      await prefs.setString(_saltKey, salt);
    }
    return salt;
  }

  Future<String> hashPassword(String password) async {
    final salt = await _getOrCreateSalt();
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }

  Future<bool> verifyPassword(String email, String password) async {
    final user = await _findUserByEmail(email);
    if (user == null || user.passwordHash.isEmpty) return false;
    final hash = await hashPassword(password);
    return user.passwordHash == hash;
  }

  Future<void> ensureLocalUser({
    required UserSession session,
    required String password,
    bool refreshPassword = false,
  }) async {
    final email = normalizeEmail(session.email);
    final existing = await _findUserByEmail(email);
    if (existing == null) {
      await saveUser(session, password: password);
      return;
    }
    if (existing.passwordHash.isNotEmpty && !refreshPassword) {
      final existingRole = UserRole.fromString(existing.role);
      if (existing.name != session.name ||
          existingRole != session.role ||
          existing.gender != session.gender) {
        await saveUser(
          UserSession(
            uid: existing.uid.startsWith('local-') ? session.uid : existing.uid,
            name: session.name,
            email: email,
            role: session.role,
            gender: session.gender,
          ),
        );
      }
      return;
    }

    final uid = existing.uid.startsWith('local-') ? session.uid : existing.uid;
    await saveUser(
      UserSession(
        uid: uid,
        name: session.name,
        email: email,
        role: session.role,
        gender: session.gender,
      ),
      password: password,
    );
  }

  Future<void> saveUser(UserSession session, {String? password}) async {
    final email = normalizeEmail(session.email);
    final existing = await _findUserByEmail(email);

    // Drop placeholder row when binding to real Firebase uid.
    if (existing != null &&
        existing.uid != session.uid &&
        existing.uid.startsWith('local-')) {
      await (_db.delete(_db.localUsers)
            ..where((t) => t.uid.equals(existing.uid)))
          .go();
    }

    var passwordHash = '';
    if (password != null) {
      passwordHash = await hashPassword(password);
    } else {
      final existing = await _findUserByEmail(email);
      passwordHash = existing?.passwordHash ?? '';
    }

    await _db.upsertUser(
      LocalUsersCompanion(
        uid: Value(session.uid),
        email: Value(email),
        name: Value(session.name),
        role: Value(session.role.toFirestore()),
        gender: Value(session.gender),
        passwordHash: Value(passwordHash),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  UserSession sessionFromLocal(LocalUser user) {
    return UserSession(
      uid: user.uid,
      name: user.name,
      email: user.email,
      role: UserRole.fromString(user.role),
      gender: user.gender,
    );
  }

  Future<UserSession?> getUserByEmail(String email) async {
    final user = await _findUserByEmail(email);
    return user == null ? null : sessionFromLocal(user);
  }

  Future<LocalUser?> _findUserByEmail(String email) async {
    final normalized = normalizeEmail(email);
    final users = await _db.select(_db.localUsers).get();
    for (final user in users) {
      if (normalizeEmail(user.email) == normalized) {
        return user;
      }
    }
    return null;
  }

  Future<UserSession?> getUserByUid(String uid) async {
    final user = await _db.getUserByUid(uid);
    return user == null ? null : sessionFromLocal(user);
  }

  Future<void> rememberLogin(String email, String password) async {
    final prefs = await _prefs;
    await prefs.setString(_lastEmailKey, normalizeEmail(email));
    await prefs.setString(_lastPasswordKey, password);
  }

  Future<void> clearRememberedLogin() async {
    final prefs = await _prefs;
    await prefs.remove(_lastEmailKey);
    await prefs.remove(_lastPasswordKey);
  }

  Future<String?> getRememberedEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_lastEmailKey);
  }

  Future<bool> refreshFirebaseAuth(
    FirebaseAuth auth, {
    String? preferredEmail,
  }) async {
    final preferred = preferredEmail != null
        ? normalizeEmail(preferredEmail)
        : null;

    if (auth.currentUser != null) {
      final currentEmail = normalizeEmail(auth.currentUser!.email ?? '');
      if (preferred == null || currentEmail == preferred) {
        return true;
      }
      await auth.signOut();
    }

    final attempts = <({String email, String password})>[];

    void addAttempt(String email, String password) {
      if (password.isEmpty) return;
      final normalized = normalizeEmail(email);
      if (preferred != null && normalized != preferred) return;
      if (attempts.any((a) => a.email == normalized)) return;
      attempts.add((email: normalized, password: password));
    }

    final prefs = await _prefs;
    final rememberedEmail = prefs.getString(_lastEmailKey);
    final rememberedPassword = prefs.getString(_lastPasswordKey);
    if (rememberedEmail != null && rememberedPassword != null) {
      addAttempt(rememberedEmail, rememberedPassword);
    }

    for (final cred in attempts) {
      try {
        await auth.signInWithEmailAndPassword(
          email: cred.email,
          password: cred.password,
        );
        if (auth.currentUser != null) {
          await rememberLogin(cred.email, cred.password);
          return true;
        }
      } catch (e) {
        debugPrint('Firebase re-auth failed for ${cred.email}: $e');
      }
    }

    return false;
  }

  Future<void> setActiveOfflineUid(String uid) async {
    final prefs = await _prefs;
    await prefs.setString(_activeUidKey, uid);
  }

  Future<String?> getActiveOfflineUid() async {
    final prefs = await _prefs;
    return prefs.getString(_activeUidKey);
  }

  Future<void> clearActiveOfflineUid() async {
    final prefs = await _prefs;
    await prefs.remove(_activeUidKey);
  }

  Future<UserSession?> getActiveOfflineSession() async {
    final uid = await getActiveOfflineUid();
    if (uid == null) return null;
    return getUserByUid(uid);
  }
}
