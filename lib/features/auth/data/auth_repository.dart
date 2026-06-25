import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/local_auth_store.dart';
import '../../../core/network/connectivity_service.dart';
import '../domain/user_session.dart';

class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    ref.watch(localAuthStoreProvider),
    ref.watch(connectivityServiceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

class AuthRepository {
  AuthRepository(
    this._auth,
    this._firestore,
    this._localAuth,
    this._connectivity,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final LocalAuthStore _localAuth;
  final ConnectivityService _connectivity;

  final _sessionUpdates = StreamController<void>.broadcast();

  void dispose() {
    _sessionUpdates.close();
  }

  void _notifySessionChanged() {
    if (!_sessionUpdates.isClosed) {
      _sessionUpdates.add(null);
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isOfflineSession => _offlineSessionActive;
  bool _offlineSessionActive = false;

  Future<UserSession?> fetchSession() async {
    if (_offlineSessionActive) {
      return _localAuth.getActiveOfflineSession();
    }

    final offlineSession = await _localAuth.getActiveOfflineSession();
    final firebaseUser = _auth.currentUser;

    if (offlineSession != null) {
      final offlineEmail = LocalAuthStore.normalizeEmail(offlineSession.email);
      final firebaseEmail = firebaseUser != null
          ? LocalAuthStore.normalizeEmail(firebaseUser.email ?? '')
          : '';
      if (firebaseUser == null || firebaseEmail != offlineEmail) {
        _offlineSessionActive = true;
        return offlineSession;
      }
    }

    if (firebaseUser != null) {
      _offlineSessionActive = false;
      final local = await _localAuth.getUserByUid(firebaseUser.uid);
      if (local != null) {
        return local;
      }
      if (await _connectivity.isOnline) {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) return null;
        final session = UserSession.fromMap(firebaseUser.uid, doc.data()!);
        await _localAuth.saveUser(session);
        return session;
      }
      return null;
    }

    if (offlineSession != null) {
      _offlineSessionActive = true;
      return offlineSession;
    }
    return null;
  }

  Stream<UserSession?> sessionStream() {
    return Stream.multi((controller) async {
      Future<void> emit() async {
        controller.add(await fetchSession());
      }

      await emit();
      final authSub = _auth.authStateChanges().listen((_) => emit());
      final refreshSub = _sessionUpdates.stream.listen((_) => emit());
      controller.onCancel = () {
        authSub.cancel();
        refreshSub.cancel();
      };
    });
  }

  Future<UserSession> signIn(String email, String password) async {
    final normalizedEmail = LocalAuthStore.normalizeEmail(email);
    final localSession = await _localAuth.getUserByEmail(normalizedEmail);
    final localPasswordOk =
        await _localAuth.verifyPassword(normalizedEmail, password);

    if (localPasswordOk && localSession != null) {
      await _localAuth.rememberLogin(normalizedEmail, password);
      if (await _connectivity.isOnline) {
        try {
          return await _signInOnline(normalizedEmail, password);
        } catch (_) {
          await _auth.signOut();
          return _activateLocalSession(localSession);
        }
      }
      return _activateLocalSession(localSession);
    }

    if (await _connectivity.isOnline) {
      return _signInOnline(normalizedEmail, password);
    }

    throw const OfflineWrongPasswordException();
  }

  Future<UserSession> _activateLocalSession(UserSession session) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final firebaseEmail =
          LocalAuthStore.normalizeEmail(firebaseUser.email ?? '');
      final sessionEmail = LocalAuthStore.normalizeEmail(session.email);
      if (firebaseEmail != sessionEmail) {
        await _auth.signOut();
      }
    }
    await _localAuth.setActiveOfflineUid(session.uid);
    _offlineSessionActive = true;
    _notifySessionChanged();
    return session;
  }

  Future<UserSession> _signInOnline(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _auth.signOut();
      throw const ProfileNotFoundException();
    }

    final session = UserSession.fromMap(uid, doc.data()!);
    await _localAuth.saveUser(session, password: password);
    await _localAuth.rememberLogin(email, password);
    await _localAuth.clearActiveOfflineUid();
    _offlineSessionActive = false;
    _notifySessionChanged();

    return session;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _localAuth.clearActiveOfflineUid();
    await _localAuth.clearRememberedLogin();
    _offlineSessionActive = false;
    _notifySessionChanged();
  }

  /// Offline login → internet back: Firebase Auth + Firestore profile for active user.
  Future<bool> promoteOfflineSessionIfOnline() async {
    if (!await _connectivity.isOnline) return false;

    final offlineSession = await _localAuth.getActiveOfflineSession();
    if (offlineSession == null && !_offlineSessionActive) {
      return _auth.currentUser != null;
    }

    final hint = offlineSession ??
        await _localAuth.getActiveOfflineSession();
    if (hint == null) return false;

    final ok = await _localAuth.refreshFirebaseAuth(
      _auth,
      preferredEmail: hint.email,
    );
    if (!ok) {
      debugPrint('promoteOfflineSession: Firebase re-auth failed for ${hint.email}');
      return false;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      debugPrint('promoteOfflineSession: users/$uid missing in Firestore');
      return false;
    }

    final profile = UserSession.fromMap(uid, doc.data()!);
    await _localAuth.saveUser(profile);
    await _localAuth.clearActiveOfflineUid();
    _offlineSessionActive = false;
    _notifySessionChanged();
    return true;
  }

  /// Firebase users/{uid}.name first, then local cache, then [fallback].
  Future<String> resolveUserDisplayName(
    String uid, {
    String fallback = '',
  }) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return fallback.trim();

    if (trimmedUid.startsWith('local-')) {
      final email = LocalAuthStore.normalizeEmail(trimmedUid.substring(6));
      final byEmail = await _localAuth.getUserByEmail(email);
      if (byEmail != null && byEmail.name.trim().isNotEmpty) {
        return byEmail.name.trim();
      }
      if (await _connectivity.isOnline) {
        try {
          final snap = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            final session = UserSession.fromMap(
              snap.docs.first.id,
              snap.docs.first.data(),
            );
            final name = session.name.trim();
            if (name.isNotEmpty) {
              await _localAuth.saveUser(session);
              return name;
            }
          }
        } catch (_) {
          // Fall through to cache/fallback.
        }
      }
    }

    if (await _connectivity.isOnline) {
      try {
        final doc = await _firestore.collection('users').doc(trimmedUid).get();
        if (doc.exists && doc.data() != null) {
          final session = UserSession.fromMap(trimmedUid, doc.data()!);
          final name = session.name.trim();
          if (name.isNotEmpty) {
            await _localAuth.saveUser(session);
            return name;
          }
        }
      } catch (_) {
        // Offline or rules — fall through to cache/fallback.
      }
    }

    final local = await _localAuth.getUserByUid(trimmedUid);
    if (local != null && local.name.trim().isNotEmpty) {
      return local.name.trim();
    }

    return fallback.trim();
  }
}
