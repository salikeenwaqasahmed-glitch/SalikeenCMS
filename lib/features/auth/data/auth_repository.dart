import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/local_auth_store.dart';
import '../../../core/auth/local_user_seed.dart';
import '../../../core/auth/seed_credentials.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/access_control.dart';
import '../domain/user_session.dart';

class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException();
}

class FirebaseAuthFailedException implements Exception {
  const FirebaseAuthFailedException(this.email);

  final String email;
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
  bool get isLoginAttemptInProgress => _loginAttemptInProgress;
  bool _offlineSessionActive = false;
  bool _loginAttemptInProgress = false;

  /// Keeps [sessionStream] on [session] while Firebase Auth is temporarily
  /// switched (e.g. staff provisioning loop).
  UserSession? _pinnedSession;

  void pinSession(UserSession session) {
    _pinnedSession = session;
  }

  void unpinSession() {
    _pinnedSession = null;
    _notifySessionChanged();
  }

  bool get isSessionPinned => _pinnedSession != null;

  UserSession? _stickySession;

  static bool _sameSession(UserSession? a, UserSession? b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.uid == b.uid && a.email == b.email;
  }

  UserSession? _commitSession(UserSession? session) {
    if (session != null) _stickySession = session;
    return session;
  }

  Future<UserSession> _finalizeOnlineSession(
    UserSession profile, {
    String? password,
  }) async {
    if (password != null) {
      await _localAuth.rememberLogin(profile.email, password);
    }
    await _localAuth.setActiveOfflineUid(profile.uid);
    _offlineSessionActive = false;
    _maybeNotifySessionChanged(profile);
    return _commitSession(profile)!;
  }

  void _maybeNotifySessionChanged(UserSession profile) {
    if (_sameSession(_stickySession, profile)) {
      _stickySession = profile;
      return;
    }
    _stickySession = profile;
    _notifySessionChanged();
  }

  /// Firestore salik rules need users/{uid}; only query when Auth matches session.
  Future<bool> canQueryRemoteSaliks(UserSession session) async {
    if (!await _connectivity.isOnline) {
      debugPrint('canQueryRemoteSaliks: offline');
      return false;
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      debugPrint('canQueryRemoteSaliks: no Firebase user');
      return false;
    }

    final firebaseEmail =
        LocalAuthStore.normalizeEmail(firebaseUser.email ?? '');
    final sessionEmail = LocalAuthStore.normalizeEmail(session.email);
    if (firebaseEmail != sessionEmail) {
      debugPrint(
        'canQueryRemoteSaliks: email mismatch firebase=$firebaseEmail session=$sessionEmail',
      );
      return false;
    }

    // Pinned only blocks when seed loop switched Firebase to another account.
    if (_pinnedSession != null &&
        LocalAuthStore.normalizeEmail(_pinnedSession!.email) != firebaseEmail) {
      debugPrint('canQueryRemoteSaliks: pinned session blocks remote');
      return false;
    }

    if (!session.uid.startsWith('local-') && firebaseUser.uid != session.uid) {
      debugPrint(
        'canQueryRemoteSaliks: uid mismatch firebase=${firebaseUser.uid} session=${session.uid}',
      );
      return false;
    }

    try {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        debugPrint('canQueryRemoteSaliks: users/${firebaseUser.uid} missing');
      }
      return doc.exists;
    } catch (e) {
      debugPrint('canQueryRemoteSaliks: users doc read failed: $e');
      return false;
    }
  }

  Stream<bool> watchRemoteSalikAccess(UserSession session) {
    return Stream.multi((controller) async {
      Future<void> emit() async {
        if (controller.isClosed) return;
        controller.add(await canQueryRemoteSaliks(session));
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

  static const _fetchSessionTimeout = Duration(seconds: 12);

  UserSession? _cachedSessionFallback() {
    if (_pinnedSession != null) return _commitSession(_pinnedSession);
    if (_stickySession != null) return _stickySession;
    return null;
  }

  Future<UserSession?> fetchSession() async {
    try {
      return await _fetchSession().timeout(
        _fetchSessionTimeout,
        onTimeout: () {
          debugPrint('fetchSession timed out; using cached session if any');
          return _cachedSessionFallback();
        },
      );
    } catch (e, st) {
      debugPrint('fetchSession failed: $e\n$st');
      return _cachedSessionFallback();
    }
  }

  Future<UserSession?> _fetchSession() async {
    if (_pinnedSession != null) {
      return _commitSession(_pinnedSession);
    }

    if (_offlineSessionActive) {
      return _commitSession(await _localAuth.getActiveOfflineSession());
    }

    final offlineSession = await _localAuth.getActiveOfflineSession();
    var firebaseUser = _auth.currentUser;
    final rememberedEmail = await _localAuth.getRememberedEmail();

    if (firebaseUser == null &&
        offlineSession == null &&
        (rememberedEmail == null || rememberedEmail.isEmpty)) {
      _stickySession = null;
      return null;
    }

    if (_loginAttemptInProgress) {
      _stickySession = null;
      return null;
    }

    if (await _connectivity.isOnline) {
      try {
        if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
          final firebaseEmail = firebaseUser != null
              ? LocalAuthStore.normalizeEmail(firebaseUser.email ?? '')
              : '';
          if (firebaseEmail != rememberedEmail) {
            await _localAuth.refreshFirebaseAuth(
              _auth,
              preferredEmail: rememberedEmail,
            );
            firebaseUser = _auth.currentUser;
          }
        } else if (firebaseUser != null) {
          // Logged out locally — drop stray Firebase session.
          await _auth.signOut();
          firebaseUser = null;
        }
      } catch (e) {
        debugPrint('fetchSession re-auth failed: $e');
        if (firebaseUser != null) {
          await _auth.signOut();
          firebaseUser = null;
        }
      }
    }

    if (offlineSession != null) {
      final offlineEmail = LocalAuthStore.normalizeEmail(offlineSession.email);
      final firebaseEmail = firebaseUser != null
          ? LocalAuthStore.normalizeEmail(firebaseUser.email ?? '')
          : '';
      if (firebaseUser == null || firebaseEmail != offlineEmail) {
        if (await _connectivity.isOnline) {
          final restored = await _localAuth.refreshFirebaseAuth(
            _auth,
            preferredEmail: offlineSession.email,
          );
          if (restored) {
            firebaseUser = _auth.currentUser;
            if (firebaseUser != null &&
                LocalAuthStore.normalizeEmail(firebaseUser.email ?? '') ==
                    offlineEmail) {
              await _localAuth.clearActiveOfflineUid();
              _offlineSessionActive = false;
            }
          }
        }
        if (firebaseUser == null ||
            LocalAuthStore.normalizeEmail(firebaseUser.email ?? '') !=
                offlineEmail) {
          _offlineSessionActive = true;
          return _commitSession(offlineSession);
        }
      }
    }

    if (firebaseUser != null) {
      _offlineSessionActive = false;
      final firebaseUid = firebaseUser.uid;
      final local = await _localAuth.getUserByUid(firebaseUid);
      if (local != null) {
        if (await _connectivity.isOnline) {
          final doc =
              await _firestore.collection('users').doc(firebaseUid).get();
          if (!doc.exists) {
            return _commitSession(await syncUserProfileWithFirebase(local));
          }
        }
        return _commitSession(local);
      }
      if (await _connectivity.isOnline) {
        final doc =
            await _firestore.collection('users').doc(firebaseUid).get();
        if (doc.exists) {
          final session = UserSession.fromMap(firebaseUid, doc.data()!);
          await _localAuth.saveUser(session);
          return _commitSession(session);
        }
        final email = LocalAuthStore.normalizeEmail(firebaseUser.email ?? '');
        final source = await _profileSourceForEmail(email);
        if (source != null) {
          return _commitSession(
            await syncUserProfileWithFirebase(
              UserSession(
                uid: firebaseUid,
                name: source.name,
                email: email,
                role: source.role,
                gender: UserSession.normalizeGender(source.gender),
              ),
            ),
          );
        }
      }
      if (_stickySession != null) return _stickySession;
      return null;
    }

    if (offlineSession != null) {
      _offlineSessionActive = true;
      return _commitSession(offlineSession);
    }
    _stickySession = null;
    return null;
  }

  Stream<UserSession?> sessionStream() {
    return Stream.multi((controller) async {
      UserSession? lastEmitted;
      var hasEmitted = false;
      var emitInFlight = false;
      var emitQueued = false;

      Future<void> emit() async {
        if (emitInFlight) {
          emitQueued = true;
          return;
        }
        emitInFlight = true;
        try {
          do {
            emitQueued = false;
            if (controller.isClosed) return;
            final session = await fetchSession();
            if (hasEmitted && _sameSession(lastEmitted, session)) continue;
            hasEmitted = true;
            lastEmitted = session;
            controller.add(session);
          } while (emitQueued);
        } finally {
          emitInFlight = false;
        }
      }

      if (!controller.isClosed) {
        final quick = _pinnedSession ?? _stickySession;
        hasEmitted = true;
        lastEmitted = quick;
        controller.add(quick);
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

  static const _onlineSignInTimeout = Duration(seconds: 10);

  Future<void> _ensureKnownStaffLocalAccount(
    String email,
    String password,
  ) async {
    final profile = LocalUserSeed.profileForEmail(email);
    if (profile == null) return;

    final existing = await _localAuth.getUserByEmail(email);
    if (existing != null) return;

    await _localAuth.ensureLocalUser(
      session: UserSession(
        uid: 'local-$email',
        name: profile.name,
        email: email,
        role: profile.role,
        gender: profile.gender,
      ),
      password: password,
      refreshPassword: true,
    );
  }

  Future<bool> _repairSeedPasswordIfNeeded(
    String email,
    String password,
    UserSession? localSession,
  ) async {
    if (localSession == null) return false;
    if (LocalUserSeed.profileForEmail(email) == null) return false;
    if (password != SeedCredentials.defaultPassword) return false;

    await _localAuth.ensureLocalUser(
      session: localSession,
      password: password,
      refreshPassword: true,
    );
    return _localAuth.verifyPassword(email, password);
  }

  Future<void> _clearSessionForLoginAttempt() async {
    _offlineSessionActive = false;
    _stickySession = null;
    _pinnedSession = null;
    await _localAuth.clearActiveOfflineUid();
    try {
      await _auth.signOut();
    } catch (_) {}
    _notifySessionChanged();
  }

  /// Online: Firebase Auth + users/{uid}. Offline: local session only.
  Future<UserSession> upgradeToFirebaseSession(
    String email,
    String password,
    UserSession localSession,
  ) async {
    final normalizedEmail = LocalAuthStore.normalizeEmail(email);
    final authed = await _localAuth
        .refreshFirebaseAuth(_auth, preferredEmail: normalizedEmail)
        .timeout(
          _onlineSignInTimeout,
          onTimeout: () => false,
        );
    if (!authed || _auth.currentUser == null) {
      throw FirebaseAuthFailedException(normalizedEmail);
    }

    final uid = _auth.currentUser!.uid;
    final source = await _profileSourceForEmail(normalizedEmail, fallback: localSession);
    if (source == null) {
      await _auth.signOut();
      throw const ProfileNotFoundException();
    }

    final doc = await _firestore.collection('users').doc(uid).get().timeout(
          _onlineSignInTimeout,
          onTimeout: () => throw TimeoutException(
            'Login timed out. Check connection and retry.',
          ),
        );

    final seed = doc.exists
        ? UserSession.fromMap(uid, doc.data()!)
        : UserSession(
            uid: uid,
            name: source.name,
            email: normalizedEmail,
            role: source.role,
            gender: UserSession.normalizeGender(source.gender),
          );

    return syncUserProfileWithFirebase(seed, password: password).timeout(
      _onlineSignInTimeout,
      onTimeout: () => throw TimeoutException(
        'Login timed out. Check connection and retry.',
      ),
    );
  }

  Future<UserSession> signIn(String email, String password) async {
    _loginAttemptInProgress = true;
    try {
      await _clearSessionForLoginAttempt();

      final normalizedEmail = LocalAuthStore.normalizeEmail(email);
      await _ensureKnownStaffLocalAccount(normalizedEmail, password);

      var localSession = await _localAuth.getUserByEmail(normalizedEmail);
      var localPasswordOk =
          await _localAuth.verifyPassword(normalizedEmail, password);

      if (!localPasswordOk) {
        localPasswordOk = await _repairSeedPasswordIfNeeded(
          normalizedEmail,
          password,
          localSession,
        );
      }

      final UserSession session;
      if (localPasswordOk && localSession != null) {
        await _localAuth.rememberLogin(normalizedEmail, password);
        if (await _connectivity.isOnline) {
          session = await upgradeToFirebaseSession(
            normalizedEmail,
            password,
            localSession,
          );
        } else {
          session = await _activateLocalSession(localSession);
        }
      } else if (await _connectivity.isOnline) {
        session = await _signInOnline(normalizedEmail, password).timeout(
          _onlineSignInTimeout,
          onTimeout: () => throw TimeoutException(
            'Login timed out. Check connection and retry.',
          ),
        );
      } else {
        throw const OfflineWrongPasswordException();
      }

      _notifySessionChanged();
      return session;
    } finally {
      _loginAttemptInProgress = false;
      _notifySessionChanged();
    }
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
    final normalizedEmail = LocalAuthStore.normalizeEmail(email);
    final source = await _profileSourceForEmail(normalizedEmail);
    if (source == null) {
      await _auth.signOut();
      throw const ProfileNotFoundException();
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final session = doc.exists
        ? UserSession.fromMap(uid, doc.data()!)
        : UserSession(
            uid: uid,
            name: source.name,
            email: normalizedEmail,
            role: source.role,
            gender: UserSession.normalizeGender(source.gender),
          );

    return syncUserProfileWithFirebase(session, password: password);
  }

  /// Ensure Firestore users/{firebaseUid} exists and local cache uses same uid.
  Future<UserSession> syncUserProfileWithFirebase(
    UserSession session, {
    String? password,
  }) async {
    final authUser = _auth.currentUser;
    if (authUser == null) return session;

    final uid = authUser.uid;
    final email = LocalAuthStore.normalizeEmail(
      authUser.email ?? session.email,
    );
    if (email.isEmpty) return session;

    final source = await _profileSourceForEmail(email, fallback: session);
    if (source == null) return session;

    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();
    final demo = LocalUserSeed.profileForEmail(email);

    final UserSession profile;
    if (doc.exists) {
      profile = UserSession.fromMap(uid, doc.data()!);
      if (_needsProfileRepair(source, profile, demo)) {
        final repaired = UserSession(
          uid: uid,
          name: source.name.isNotEmpty ? source.name : profile.name,
          email: email,
          role: source.role,
          gender: UserSession.normalizeGender(
            source.gender.isNotEmpty ? source.gender : profile.gender,
          ),
          avatar: profile.avatar,
        );
        await ref.set(repaired.toMap(), SetOptions(merge: true));
        await _localAuth.saveUser(repaired, password: password);
        debugPrint(
          'Repaired users/$uid → role=${repaired.role.toFirestore()} gender=${repaired.gender}',
        );
        return _finalizeOnlineSession(repaired, password: password);
      }
      if (profile.uid != uid) {
        final rebound = UserSession(
          uid: uid,
          name: profile.name,
          email: email,
          role: profile.role,
          gender: profile.gender,
          avatar: profile.avatar,
        );
        await _localAuth.saveUser(rebound, password: password);
        return _finalizeOnlineSession(rebound, password: password);
      }
      await _localAuth.saveUser(profile, password: password);
      return _finalizeOnlineSession(profile, password: password);
    }

    final created = UserSession(
      uid: uid,
      name: source.name,
      email: email,
      role: source.role,
      gender: UserSession.normalizeGender(source.gender),
      avatar: session.uid == uid ? session.avatar : null,
    );

    await ref.set(created.toMap(), SetOptions(merge: true));
    await _localAuth.saveUser(created, password: password);
    debugPrint('Synced users/$uid for $email');
    return _finalizeOnlineSession(created, password: password);
  }

  bool _shouldRepairUserProfile(UserSession local, UserSession remote) {
    if (AccessControl.canApprove(local.role) &&
        !AccessControl.canApprove(remote.role)) {
      return true;
    }
    if (remote.gender.trim().isEmpty && local.gender.trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  bool _needsProfileRepair(
    UserSession local,
    UserSession remote,
    UserSession? demo,
  ) {
    if (_shouldRepairUserProfile(local, remote)) return true;
    if (demo == null) return false;
    if (local.role != remote.role) return true;
    final remoteGender = UserSession.normalizeGender(remote.gender);
    final localGender = UserSession.normalizeGender(local.gender);
    return remoteGender != localGender && localGender.isNotEmpty;
  }

  Future<UserSession?> _profileSourceForEmail(
    String email, {
    UserSession? fallback,
  }) async {
    return await _localAuth.getUserByEmail(email) ??
        LocalUserSeed.profileForEmail(email) ??
        fallback;
  }

  Future<bool> hasPersistedLoginIntent() async {
    if (_offlineSessionActive) return true;
    final remembered = await _localAuth.getRememberedEmail();
    if (remembered != null && remembered.isNotEmpty) return true;
    return await _localAuth.getActiveOfflineUid() != null;
  }

  Future<void> signOut() async {
    _offlineSessionActive = false;
    _stickySession = null;
    _pinnedSession = null;
    await _localAuth.clearActiveOfflineUid();
    await _localAuth.clearRememberedLogin();
    await _auth.signOut();
    _notifySessionChanged();
  }

  /// Offline login → internet back: Firebase Auth + Firestore profile for active user.
  Future<bool> promoteOfflineSessionIfOnline() async {
    if (!await _connectivity.isOnline) return false;
    if (!await hasPersistedLoginIntent()) {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      return false;
    }

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
      final email = LocalAuthStore.normalizeEmail(
        _auth.currentUser?.email ?? hint.email,
      );
      final source = await _profileSourceForEmail(email, fallback: hint);
      if (source == null) {
        debugPrint('promoteOfflineSession: users/$uid missing in Firestore');
        return false;
      }
      final bootstrapped = UserSession(
        uid: uid,
        name: source.name,
        email: email,
        role: source.role,
        gender: UserSession.normalizeGender(source.gender),
      );
      await syncUserProfileWithFirebase(bootstrapped);
      return true;
    }

    await syncUserProfileWithFirebase(
      UserSession.fromMap(uid, doc.data()!),
    );
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
