import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/data/seed_service.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../saliks/presentation/providers/salik_provider.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_role.dart';
import '../../domain/user_session.dart';

final seedMessageProvider = StateProvider<String?>((ref) => null);

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
    try {
      final session = await _repo.signIn(email, password);
      state = const AsyncData(null);
      _runPostLoginWork(session, password);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _runPostLoginWork(UserSession session, String password) {
    Future.microtask(() async {
      final online = await _ref.read(connectivityServiceProvider).isOnline;
      if (!online || _repo.currentUser == null) return;

      _repo.pinSession(session);
      try {
        if (session.role == UserRole.admin) {
          try {
            final seed = SeedService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            );
            await seed.seedIfNeeded();
            await seed.ensureStaffUsers(
              restoreEmail: session.email,
              restorePassword: password,
            );
            _ref.read(seedMessageProvider.notifier).state = 'seed_success';
          } catch (e, st) {
            debugPrint('post-login seed failed: $e\n$st');
            _ref.read(seedMessageProvider.notifier).state = 'seed_failed';
          }
        }

        try {
          await _repo.syncUserProfileWithFirebase(session, password: password);
        } catch (e, st) {
          debugPrint('post-login profile sync failed: $e\n$st');
        }

        try {
          await _ref.read(syncServiceProvider).hydrate(session);
        } catch (e, st) {
          debugPrint('post-login hydrate failed: $e\n$st');
        }
      } finally {
        _repo.unpinSession();
      }
    });
  }

  Future<void> signOut() async {
    await _repo.signOut();
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
