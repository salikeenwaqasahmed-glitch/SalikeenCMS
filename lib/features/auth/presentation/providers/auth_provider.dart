import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/auth/local_auth_store.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/data/seed_service.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../saliks/presentation/providers/salik_provider.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_role.dart';
import '../../domain/user_session.dart';

final seedMessageProvider = StateProvider<String?>((ref) => null);

/// True while [_runPostLoginWork] owns hydrate/sync (blocks bootstrap duplicate).
final postLoginSyncInFlightProvider = StateProvider<bool>((ref) => false);

/// Set when post-login sync fails; UI shows SnackBar once.
final loginSyncErrorProvider = StateProvider<String?>((ref) => null);

final authStateProvider = StreamProvider<UserSession?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.sessionStream();
});

final currentSessionProvider = Provider<UserSession?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo, this._ref) : super(const AsyncData(null));

  final AuthRepository _repo;
  final Ref _ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    _ref.read(loginSyncErrorProvider.notifier).state = null;
    try {
      final session = await _repo.signIn(email, password);
      state = const AsyncData(null);
      notifyRouterAuthChanged(_ref);
      _runPostLoginWork(session, password);
    } catch (e, st) {
      debugPrint('signIn failed: $e\n$st');
      state = AsyncError(e, st);
    }
  }

  void _runPostLoginWork(UserSession session, String password) {
    Future.microtask(() async {
      final online = await _ref.read(connectivityServiceProvider).isOnline;
      if (!online) return;

      _ref.read(postLoginSyncInFlightProvider.notifier).state = true;
      _repo.pinSession(session);
      try {
        if (_repo.currentUser == null) {
          final restored = await _ref
              .read(localAuthStoreProvider)
              .refreshFirebaseAuth(
                FirebaseAuth.instance,
                preferredEmail: session.email,
              );
          if (!restored) {
            debugPrint(
              'post-login: Firebase auth not restored for ${session.email}',
            );
            _ref.read(loginSyncErrorProvider.notifier).state =
                'refreshFirebaseAuth: Firebase login failed';
            return;
          }
        }

        if (_repo.currentUser == null) return;

        var active = session;
        try {
          active = await _repo.syncUserProfileWithFirebase(
            session,
            password: password,
          );
        } catch (e, st) {
          debugPrint('post-login profile sync failed: $e\n$st');
        }

        final sync = _ref.read(syncServiceProvider);
        try {
          await sync.hydrate(active);
          if (sync.lastSyncError != null) {
            _ref.read(loginSyncErrorProvider.notifier).state =
                sync.lastSyncError;
          }
        } catch (e, st) {
          debugPrint('post-login hydrate failed: $e\n$st');
          _ref.read(loginSyncErrorProvider.notifier).state = e.toString();
        }

        if (active.role == UserRole.admin) {
          try {
            final seed = SeedService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            );
            await seed.seedIfNeeded();
            await seed.ensureStaffUsers(
              restoreEmail: active.email,
              restorePassword: password,
            );
            _ref.read(seedMessageProvider.notifier).state = 'seed_success';
          } catch (e, st) {
            debugPrint('post-login seed failed: $e\n$st');
            _ref.read(seedMessageProvider.notifier).state = 'seed_failed';
          }
        }
      } finally {
        _repo.unpinSession();
        _ref.read(postLoginSyncInFlightProvider.notifier).state = false;
      }
    });
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
    _ref.read(loginSyncErrorProvider.notifier).state = null;
    _ref.invalidate(salikFilterProvider);
  }
}

final syncNowControllerProvider =
    StateNotifierProvider<SyncNowController, AsyncValue<SyncNowResult>>((ref) {
  return SyncNowController(ref);
});

class SyncNowResult {
  const SyncNowResult({required this.ok, this.error});

  final bool ok;
  final String? error;
}

class SyncNowController extends StateNotifier<AsyncValue<SyncNowResult>> {
  SyncNowController(this._ref) : super(const AsyncData(SyncNowResult(ok: false)));

  final Ref _ref;

  Future<void> syncNow() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final sync = _ref.read(syncServiceProvider);
      final ok = await sync.syncNow();
      return SyncNowResult(ok: ok, error: sync.lastSyncError);
    });
  }
}
