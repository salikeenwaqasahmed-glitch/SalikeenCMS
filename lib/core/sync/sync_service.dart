import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user_session.dart';
import '../../features/saliks/domain/entities/area.dart';
import '../../features/saliks/domain/entities/city.dart';
import '../../features/saliks/domain/entities/approval_status.dart';
import '../../features/saliks/domain/entities/salik.dart';
import '../auth/local_user_seed.dart';
import '../auth/local_auth_store.dart';
import '../data/reference_data.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import '../utils/access_control.dart';
import '../../features/saliks/presentation/providers/area_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(localAuthStoreProvider),
    ref.watch(authRepositoryProvider),
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
  ref.onDispose(service.dispose);
  return service;
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.syncQueue).watch().map((rows) => rows.length);
});

final syncBootstrapProvider = Provider<void>((ref) {
  ref.watch(syncServiceProvider).start(ref);
});

class SyncService {
  SyncService(
    this._db,
    this._connectivity,
    this._localAuth,
    this._authRepo,
    this._firestore,
    this._auth,
  );

  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final LocalAuthStore _localAuth;
  final AuthRepository _authRepo;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<bool>? _connectivitySub;
  bool _syncing = false;
  String? lastSyncError;
  Ref? _ref;

  void start(Ref ref) {
    _ref = ref;
    unawaited(_purgeLocalStaleQueue());
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onlineStream.listen((online) {
      if (online) {
        unawaited(_purgeLocalStaleQueue());
        unawaited(syncNow());
      }
    });
    unawaited(_connectivity.isOnline.then((online) {
      if (online) {
        unawaited(_purgeLocalStaleQueue());
        unawaited(syncNow());
      }
    }));
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Drop orphan queue rows when local rows are already synced (no network needed).
  Future<void> repairSyncQueue() async {
    await _purgeLocalStaleQueue();
    if (!await _connectivity.isOnline) return;
    await _adoptRemoteApprovalAhead();
    await _finalizeSyncQueue();
  }

  Future<bool> syncNow({UserSession? sessionOverride}) async {
    if (_syncing) return false;
    if (!await _connectivity.isOnline) return false;

    _syncing = true;
    lastSyncError = null;
    try {
      await _syncPhase('purgeLocalStaleQueue', _purgeLocalStaleQueue);
      await _syncPhase('promoteOfflineSession', _authRepo.promoteOfflineSessionIfOnline);

      final sessionHint = sessionOverride ?? await _currentSession();
      if (sessionHint == null) {
        lastSyncError = 'ensureUserProfile: no local session';
        return false;
      }

      final authed = await _syncPhase(
        'refreshFirebaseAuth',
        () => _localAuth.refreshFirebaseAuth(
          _auth,
          preferredEmail: sessionHint.email,
        ),
      );
      if (!authed) {
        lastSyncError = 'refreshFirebaseAuth: Firebase login failed';
        debugPrint('Sync skipped: Firebase Auth not available');
        return false;
      }

      final session = await _syncPhase(
        'ensureUserProfile',
        () => _ensureUserProfile(sessionHint),
      );
      if (session == null) {
        lastSyncError ??= 'ensureUserProfile: users/{uid} profile missing';
        return false;
      }

      await _syncPhase('adoptRemoteApprovalAhead', _adoptRemoteApprovalAhead);
      await _syncPhase('pushQueue', () => _pushQueue(session));
      await _syncPhase('finalizeSyncQueue', _finalizeSyncQueue);
      await _syncPhase('pullFromFirestore', () => pullFromFirestore(session));
      await _syncPhase('finalizeSyncQueue', _finalizeSyncQueue);
      final remaining = await _db.pendingSyncCount();
      if (remaining > 0) {
        lastSyncError = 'syncQueue: $remaining item(s) still pending';
      }
      return remaining == 0;
    } catch (e, st) {
      lastSyncError ??= e.toString();
      debugPrint('Sync failed: $e\n$st');
      return false;
    } finally {
      await _purgeLocalStaleQueue();
      _syncing = false;
    }
  }

  Future<T> _syncPhase<T>(String name, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      lastSyncError = '$name: $e';
      debugPrint('Sync phase $name failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> hydrate(UserSession session) async {
    if (!await _connectivity.isOnline) return;
    await _authRepo.promoteOfflineSessionIfOnline();
    if (!await _localAuth.refreshFirebaseAuth(
      _auth,
      preferredEmail: session.email,
    )) {
      return;
    }
    final resolved = await _ensureUserProfile(session);
    if (resolved == null) return;
    await _adoptRemoteApprovalAhead();
    await _pushQueue(resolved);
    await _finalizeSyncQueue();
    try {
      await pullFromFirestore(resolved);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      debugPrint('hydrate pull skipped: ${e.code} ${e.message}');
    }
    await _purgeLocalStaleQueue();
    await _finalizeSyncQueue();
  }

  /// Links Firebase Auth uid to Firestore users/{uid} — required by security rules.
  Future<UserSession?> _ensureUserProfile(UserSession? session) async {
    if (_auth.currentUser == null) return session;

    final email = LocalAuthStore.normalizeEmail(
      _auth.currentUser!.email ?? session?.email ?? '',
    );
    final hint = session ??
        await _localAuth.getUserByEmail(email) ??
        LocalUserSeed.profileForEmail(email);
    if (hint == null) {
      debugPrint('Sync blocked: no profile source for ${_auth.currentUser!.uid}');
      return null;
    }

    try {
      return await _authRepo.syncUserProfileWithFirebase(hint);
    } on FirebaseException catch (e) {
      debugPrint(
        'Profile sync denied users/${_auth.currentUser!.uid}: ${e.code} ${e.message}',
      );
      return null;
    }
  }

  Map<String, dynamic> _approvalPatch(Salik salik, String authUid) {
    return {
      'approvalStatus': salik.approvalStatus.toFirestore(),
      'isActive': salik.isActive,
      'approvedByUid': authUid,
      'approvedByName': salik.approvedByName,
      'approvedAt': salik.approvedAt,
      'modifiedDate': salik.modifiedDate,
      'genderId': salik.genderId,
      'mobileNumber': salik.mobileNumber,
    };
  }

  Future<void> _pushQueue(UserSession session) async {
    final items = await _db.pendingSyncItems();
    const priority = {'cities': 0, 'areas': 1, 'saliks': 2};
    items.sort((a, b) {
      final left = priority[a.collection] ?? 9;
      final right = priority[b.collection] ?? 9;
      if (left != right) return left.compareTo(right);
      return a.id.compareTo(b.id);
    });

    for (final item in items) {
      try {
        if (!await _db.syncQueueItemExists(item.id)) {
          continue;
        }

        switch (item.collection) {
          case 'saliks':
            if (!await _canPushSalikQueueItem(item, session)) {
              if (AccessControl.isEditor(session.role)) {
                debugPrint(
                  'Dropped stale editor queue saliks/${item.docId} ${item.operation}',
                );
                await _db.removeSyncItem(item.id);
              }
              continue;
            }
            final pushed = await _pushSalikFromLocal(item, session);
            if (!pushed) {
              final local = await _db.getSalikById(item.docId);
              if (local == null || local.syncStatus == synced) {
                await _db.removeSyncItem(item.id);
              }
            }
          case 'cities':
            final decoded = Map<String, dynamic>.from(
              jsonDecode(item.payloadJson) as Map,
            );
            await _pushCity(item.operation, item.docId, decoded);
            await _db.removeSyncItem(item.id);
          case 'areas':
            final decoded = Map<String, dynamic>.from(
              jsonDecode(item.payloadJson) as Map,
            );
            await _pushArea(item.operation, item.docId, decoded);
            await _db.removeSyncItem(item.id);
        }
      } catch (e) {
        if (item.collection == 'saliks' &&
            e.toString().contains('permission-denied')) {
          final local = await _db.getSalikById(item.docId);
          if (local != null) {
            await _logSalikPushDenied(
              item.docId,
              _salikPayloadForPush(local.toSalik()),
            );
          }
        }
        debugPrint(
          'Push queue failed ${item.collection}/${item.docId} ${item.operation}: $e',
        );
        await _db.updateSyncError(item.id, e.toString(), item.retryCount + 1);
      }
    }
  }

  /// Editor device: admin approved on server — adopt before push can overwrite with stale pending.
  Future<void> _adoptRemoteApprovalAhead() async {
    final rows = await _db.getAllSaliks(
      approvalStatus: ApprovalStatus.pending.toFirestore(),
    );
    for (final row in rows) {
      await _adoptServerApprovalForSalik(row.salikId);
    }
  }

  Future<bool> _adoptServerApprovalForSalik(String salikId) async {
    final local = await _db.getSalikById(salikId);
    if (local == null || !local.toSalik().isPending) return false;

    try {
      final snap = await _firestore.collection('saliks').doc(salikId).get();
      if (!snap.exists) return false;

      final server = Salik.fromMap(snap.data()!, id: salikId);
      if (server.isPending) return false;

      await _db.upsertSalik(
        salikToCompanion(server, syncStatus: synced),
      );
      await _db.removeSyncItemsForDoc('saliks', salikId);
      return true;
    } catch (e) {
      debugPrint('Adopt approval $salikId: $e');
      return false;
    }
  }

  Future<bool> _canPushSalikQueueItem(SyncQueueData item, UserSession session) async {
    final local = await _db.getSalikById(item.docId);
    if (local == null) return false;

    final salik = local.toSalik();
    final gender = AccessControl.genderFilter(session);
    if (gender != null && salik.genderId != gender) {
      return false;
    }

    if (AccessControl.isEditor(session.role)) {
      return salik.isPending && item.operation == 'create';
    }

    if (item.operation == 'delete' && !AccessControl.canDelete(session.role)) {
      return false;
    }

    if (AccessControl.canApprove(session.role)) {
      return true;
    }

    return false;
  }

  /// Pushes current local salik row so stale queue payloads cannot undo approval.
  Future<bool> _pushSalikFromLocal(
    SyncQueueData item,
    UserSession session,
  ) async {
    final local = await _db.getSalikById(item.docId);
    if (local == null) {
      return false;
    }

    if (local.syncStatus == synced) {
      return false;
    }

    final localSalik = local.toSalik();
    if (AccessControl.isEditor(session.role) && !localSalik.isPending) {
      debugPrint(
        'Editor skip push saliks/${item.docId}: only pending create allowed',
      );
      await _db.removeSyncItem(item.id);
      return false;
    }

    if (localSalik.isPending) {
      final adopted = await _adoptServerApprovalForSalik(item.docId);
      if (adopted) return false;
    }

    var operation = switch (local.syncStatus) {
      pendingCreate => 'create',
      pendingDelete => 'delete',
      _ => 'update',
    };
    if (operation == 'create' && !AccessControl.isEditor(session.role)) {
      final exists = await _firestore.collection('saliks').doc(item.docId).get();
      if (exists.exists) {
        operation = 'update';
      }
    }

    if (AccessControl.isEditor(session.role) && operation != 'create') {
      debugPrint(
        'Editor skip push saliks/${item.docId}: operation $operation denied',
      );
      await _db.removeSyncItem(item.id);
      return false;
    }

    final payload = operation == 'delete'
        ? {'salikId': item.docId}
        : _salikPayloadForPush(local.toSalik());

    await _pushSalik(operation, item.docId, payload);
    await _db.removeSyncItem(item.id);
    return true;
  }

  /// Network up enough to try Firestore (Wi‑Fi/mobile). Real reachability checked on write.
  Future<bool> shouldPushToServer() => _connectivity.shouldAttemptSync;

  static const _serverOnly = GetOptions(source: Source.server);

  Future<DocumentSnapshot<Map<String, dynamic>>> _getSalikFromServer(
    DocumentReference<Map<String, dynamic>> ref,
  ) {
    return ref.get(_serverOnly).timeout(const Duration(seconds: 15));
  }

  Future<void> _writeApprovalToServer(
    DocumentReference<Map<String, dynamic>> ref,
    Salik salik,
    String authUid,
  ) async {
    final patch = _approvalPatch(salik, authUid);
    try {
      await ref.update(patch);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        await ref.set(_salikPayloadForPush(salik));
      } else {
        rethrow;
      }
    }
    try {
      await _firestore
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort — verify reads from server below.
    }
  }

  Future<String?> _verifyApprovalOnServer(
    DocumentReference<Map<String, dynamic>> ref,
    Salik salik,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        final verify = await _getSalikFromServer(ref);
        if (!verify.exists) {
          return 'Salik missing on server after save';
        }
        final server = Salik.fromMap(verify.data()!, id: salik.salikId);
        if (server.approvalStatus != salik.approvalStatus) {
          if (attempt < 2) continue;
          final uid = _auth.currentUser?.uid ?? '';
          return 'Server still ${server.approvalStatus.toFirestore()} — users/$uid needs role approval + gender ${salik.genderId}';
        }
        if (!salik.isPending &&
            (server.approvedByUid.isEmpty || server.approvedAt.isEmpty)) {
          return 'Approval fields empty on server — redeploy Firestore rules';
        }
        return null;
      } on TimeoutException {
        if (attempt >= 2) {
          return 'Server timeout — check connection and try again';
        }
      }
    }
    return 'Server verify failed';
  }

  /// Push one salik immediately (approve/reject). Returns error message or null on success.
  Future<String?> pushSalikNow(Salik salik) async {
    if (!await shouldPushToServer()) {
      return 'No internet — connect and try again';
    }

    await _authRepo.promoteOfflineSessionIfOnline();

    final sessionHint = await _currentSession();
    if (!await _localAuth.refreshFirebaseAuth(
      _auth,
      preferredEmail: sessionHint?.email,
    )) {
      return 'Firebase login failed — sign in online as approval first';
    }

    final session = await _ensureUserProfile(await _currentSession());
    if (session == null) {
      return 'Firestore users/{uid} profile missing — sign in online once';
    }

    final authUid = _auth.currentUser?.uid;
    if (authUid == null || authUid.isEmpty) {
      return 'Firebase Auth session missing';
    }

    final ref = _firestore.collection('saliks').doc(salik.salikId);

    try {
      try {
        await _firestore.enableNetwork();
      } catch (_) {
        // Already online.
      }

      if (!salik.isPending) {
        final existing = await ref.get();
        if (!existing.exists) {
          await ref.set(_salikPayloadForPush(salik));
        } else {
          final server = Salik.fromMap(existing.data()!, id: salik.salikId);
          if (server.isPending) {
            await _writeApprovalToServer(ref, salik, authUid);
          } else if (server.approvalStatus != salik.approvalStatus) {
            return 'Server already ${server.approvalStatus.toFirestore()}';
          }
        }
        final verifyError = await _verifyApprovalOnServer(ref, salik);
        if (verifyError != null) return verifyError;
      } else {
        final clean = _salikPayloadForPush(salik);
        final snap = await ref.get();
        if (snap.exists) {
          await ref.update(clean);
        } else {
          await ref.set(clean);
        }
        final verify = await _getSalikFromServer(ref);
        if (!verify.exists) {
          return 'Salik missing on server after save';
        }
        final server = Salik.fromMap(verify.data()!, id: salik.salikId);
        if (server.approvalStatus != ApprovalStatus.pending) {
          return 'Server status ${server.approvalStatus.toFirestore()} — expected pending';
        }
      }

      final syncedSalik = salik.copyWith(approvedByUid: authUid);
      await _cacheSalik(syncedSalik);
      debugPrint(
        'pushSalikNow OK ${syncedSalik.salikId} '
        '${syncedSalik.approvalStatus.toFirestore()}',
      );
      return null;
    } on FirebaseException catch (e) {
      debugPrint('pushSalikNow ${salik.salikId}: ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        return 'Permission denied — users/$authUid needs role approval + gender ${salik.genderId} (have ${session.role.toFirestore()}/${session.gender})';
      }
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return 'No internet — connect and try again';
      }
      return e.message ?? e.code;
    } on TimeoutException {
      return 'Server timeout — check connection and try again';
    }
  }

  /// Online Firebase session with approver role — used before Firestore push.
  Future<({UserSession? session, String? error})> prepareApproverSession(
    UserSession hint,
  ) async {
    if (!await shouldPushToServer()) {
      return (session: hint, error: null);
    }
    await _authRepo.promoteOfflineSessionIfOnline();
    if (!await _localAuth.refreshFirebaseAuth(
      _auth,
      preferredEmail: hint.email,
    )) {
      return (
        session: null,
        error: 'Firebase login failed — sign in online first',
      );
    }
    final resolved = await _ensureUserProfile(hint);
    if (resolved == null) {
      return (
        session: null,
        error: 'Firestore users/{uid} profile missing',
      );
    }
    if (!AccessControl.canApprove(resolved.role)) {
      return (
        session: null,
        error: 'Role is ${resolved.role} — need approval',
      );
    }
    return (session: resolved, error: null);
  }

  Future<void> _logSalikPushDenied(
    String docId,
    Map<String, dynamic> payload,
  ) async {
    final uid = _auth.currentUser?.uid;
    debugPrint(
      'Salik push denied doc=$docId authUid=$uid '
      'approvalStatus=${payload['approvalStatus']} '
      'isActive=${payload['isActive']} genderId=${payload['genderId']}',
    );
    if (uid == null || uid.isEmpty) {
      debugPrint('Salik push denied: Firebase Auth uid missing');
      return;
    }
    try {
      final user = await _firestore.collection('users').doc(uid).get();
      if (user.exists) {
        debugPrint('Salik push denied users/$uid: ${user.data()}');
      } else {
        debugPrint(
          'Salik push denied: users/$uid MISSING — rules isEditor() fails',
        );
      }
    } catch (e) {
      debugPrint('Salik push denied: could not read users/$uid: $e');
    }
  }

  Map<String, dynamic> _salikPayloadForPush(Salik salik) {
    var pushSalik = salik;
    final authUid = _auth.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) {
      if (salik.isPending) {
        pushSalik = salik.copyWith(addedByUid: authUid);
      } else if (salik.approvedByUid.isEmpty ||
          salik.approvedByUid.startsWith('local-')) {
        pushSalik = salik.copyWith(approvedByUid: authUid);
      }
    }
    return Map<String, dynamic>.from(pushSalik.toMap())
      ..removeWhere((_, value) => value == null);
  }

  Future<void> _pushSalik(
    String operation,
    String docId,
    Map<String, dynamic> payload,
  ) async {
    final clean = Map<String, dynamic>.from(payload)
      ..removeWhere((_, value) => value == null);
    final ref = _firestore.collection('saliks').doc(docId);
    switch (operation) {
      case 'create':
        final existing = await ref.get();
        if (existing.exists) {
          final server = Salik.fromMap(existing.data()!, id: docId);
          if (server.isPending) {
            await _cacheSalik(server);
            return;
          }
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'already-exists',
            message:
                'Salik $docId exists as ${server.approvalStatus.toFirestore()}',
          );
        }
        await ref.set(clean);
        await _cacheSalik(Salik.fromMap(clean, id: docId));
      case 'update':
        final exists = await ref.get();
        if (exists.exists) {
          final server = Salik.fromMap(exists.data()!, id: docId);
          final incoming = Salik.fromMap(clean, id: docId);
          final authUid = _auth.currentUser?.uid ?? '';
          if (server.isPending &&
              !incoming.isPending &&
              authUid.isNotEmpty) {
            await ref.update(_approvalPatch(incoming, authUid));
          } else {
            await ref.update(clean);
          }
        } else {
          await ref.set(clean);
        }
        await _cacheSalik(Salik.fromMap(clean, id: docId));
      case 'delete':
        await ref.delete();
        await _db.deleteSalikLocal(docId);
        await _db.removeSyncItemsForDoc('saliks', docId);
    }
  }

  Future<void> _pushCity(
    String operation,
    String docId,
    Map<String, dynamic> payload,
  ) async {
    final ref = _firestore.collection('cities').doc(docId);
    switch (operation) {
      case 'create':
        await ref.set(payload);
        await _db.upsertCity(
          cityToCompanion(City.fromMap(payload), syncStatus: synced),
        );
      case 'update':
        await ref.update(payload);
        await _db.upsertCity(
          cityToCompanion(City.fromMap(payload), syncStatus: synced),
        );
      case 'delete':
        await ref.delete();
    }
  }

  Future<void> _pushArea(
    String operation,
    String docId,
    Map<String, dynamic> payload,
  ) async {
    final ref = _firestore.collection('areas').doc(docId);
    switch (operation) {
      case 'create':
        await ref.set(payload);
        await _db.upsertArea(
          areaToCompanion(Area.fromMap(payload), syncStatus: synced),
        );
      case 'update':
        await ref.update(payload);
        await _db.upsertArea(
          areaToCompanion(Area.fromMap(payload), syncStatus: synced),
        );
      case 'delete':
        await ref.delete();
    }
  }

  Future<void> pullFromFirestore(UserSession session) async {
    if (!await _connectivity.isOnline) return;

    await _pullSaliks(session);
    await _pullCities();
    await _pullAreas();
    _invalidateLocationProviders();
  }

  void _invalidateLocationProviders() {
    final ref = _ref;
    if (ref == null) return;
    ref.invalidate(citiesProvider);
    ref.invalidate(cityByIdProvider);
    ref.invalidate(areaByIdProvider);
  }

  Future<void> _pullSaliks(UserSession session) async {
    Query<Map<String, dynamic>> query = _firestore.collection('saliks');
    final gender = AccessControl.genderFilter(session);
    if (gender != null) {
      query = query.where('genderId', isEqualTo: gender);
    }

    final snapshot = await query.get();
    final serverIds = <String>{};
    for (final doc in snapshot.docs) {
      serverIds.add(doc.id);
      final serverSalik = Salik.fromMap(doc.data(), id: doc.id);
      await _mergeSalikFromServer(serverSalik);
    }
    await _pruneStaleSalikCache(serverIds, gender);
  }

  /// Keep Firestore copy in Drift for offline read — outbox rows win in merge.
  Future<void> _cacheSalik(Salik salik) async {
    await _db.upsertSalik(salikToCompanion(salik, syncStatus: synced));
    await _db.removeSyncItemsForDoc('saliks', salik.salikId);
  }

  Future<void> _pruneStaleSalikCache(
    Set<String> serverIds,
    String? gender,
  ) async {
    final localRows = await _db.getAllSaliks(genderFilter: gender);
    for (final row in localRows) {
      if (row.syncStatus != synced) continue;
      if (!serverIds.contains(row.salikId)) {
        await _db.deleteSalikLocal(row.salikId);
      }
    }
  }

  Future<void> _mergeSalikFromServer(Salik serverSalik) async {
    final local = await _db.getSalikById(serverSalik.salikId);
    if (local != null && local.syncStatus != synced) {
      final localSalik = local.toSalik();
      if (!localSalik.isPending && serverSalik.isPending) {
        return;
      }
      if (localSalik.isPending && !serverSalik.isPending) {
        await _cacheSalik(serverSalik);
      }
      return;
    }

    await _cacheSalik(serverSalik);
  }

  /// Remove queue rows for entities already marked synced locally.
  Future<void> _purgeLocalStaleQueue() async {
    for (final row in await _db.getAllSaliks()) {
      if (row.syncStatus == synced) {
        await _db.removeSyncItemsForDoc('saliks', row.salikId);
        continue;
      }
    }
    for (final row in await _db.getAllCities()) {
      if (row.syncStatus == synced) {
        await _db.removeSyncItemsForDoc('cities', row.cityId);
      }
    }
    for (final row in await _db.getAllAreas()) {
      if (row.syncStatus == synced) {
        await _db.removeSyncItemsForDoc('areas', row.areaId);
      }
    }
  }

  /// Clear queue rows that are redundant or already on Firestore.
  Future<void> _finalizeSyncQueue() async {
    await _purgeLocalStaleQueue();

    for (final item in await _db.pendingSyncItems()) {
      switch (item.collection) {
        case 'saliks':
          await _finalizeSalikQueueItem(item);
        case 'cities':
          await _finalizeCityQueueItem(item);
        case 'areas':
          await _finalizeAreaQueueItem(item);
        default:
          debugPrint('Drop unknown sync item ${item.collection}/${item.docId}');
          await _db.removeSyncItem(item.id);
      }
    }
  }

  Future<void> _finalizeSalikQueueItem(SyncQueueData item) async {
    final local = await _db.getSalikById(item.docId);
    if (local == null) {
      await _db.removeSyncItem(item.id);
      return;
    }
    if (local.syncStatus == synced) {
      await _db.removeSyncItemsForDoc('saliks', item.docId);
      return;
    }

    if (!await _connectivity.isOnline) return;

    try {
      final snap = await _firestore.collection('saliks').doc(item.docId).get();
      if (!snap.exists) return;

      final server = Salik.fromMap(snap.data()!, id: item.docId);
      final localSalik = local.toSalik();

      // Local approve/reject ahead of stale server pending — keep local, retry push.
      if (!localSalik.isPending && server.isPending) {
        return;
      }

      final serverAhead = localSalik.isPending && !server.isPending;
      final sameApproval =
          localSalik.approvalStatus == server.approvalStatus;

      if (!serverAhead && !sameApproval) {
        return;
      }

      await _cacheSalik(server);
    } catch (e) {
      debugPrint('Finalize salik queue ${item.docId}: $e');
    }
  }

  Future<void> _finalizeCityQueueItem(SyncQueueData item) async {
    final local = await _db.getCityById(item.docId);
    if (local == null && item.retryCount > 0) {
      await _db.removeSyncItem(item.id);
      return;
    }
    if (local?.syncStatus == synced) {
      await _db.removeSyncItemsForDoc('cities', item.docId);
      return;
    }

    if (!await _connectivity.isOnline) return;

    try {
      final snap = await _firestore.collection('cities').doc(item.docId).get();
      if (!snap.exists) return;
      final city = City.fromMap(snap.data()!, id: item.docId);
      await _db.upsertCity(cityToCompanion(city, syncStatus: synced));
      await _db.removeSyncItemsForDoc('cities', item.docId);
    } catch (e) {
      debugPrint('Finalize city queue ${item.docId}: $e');
    }
  }

  Future<void> _finalizeAreaQueueItem(SyncQueueData item) async {
    final local = await _db.getAreaById(item.docId);
    if (local == null && item.retryCount > 0) {
      await _db.removeSyncItem(item.id);
      return;
    }
    if (local?.syncStatus == synced) {
      await _db.removeSyncItemsForDoc('areas', item.docId);
      return;
    }

    if (!await _connectivity.isOnline) return;

    try {
      final snap = await _firestore.collection('areas').doc(item.docId).get();
      if (!snap.exists) return;
      final area = Area.fromMap(snap.data()!, id: item.docId);
      await _db.upsertArea(areaToCompanion(area, syncStatus: synced));
      await _db.removeSyncItemsForDoc('areas', item.docId);
    } catch (e) {
      debugPrint('Finalize area queue ${item.docId}: $e');
    }
  }

  Future<void> _pullCities() async {
    final snapshot = await _firestore.collection('cities').get();
    if (snapshot.docs.isEmpty) {
      for (final city in kCities) {
        await _db.upsertCity(cityToCompanion(city));
      }
      return;
    }
    for (final doc in snapshot.docs) {
      try {
        final city = City.fromMap(doc.data(), id: doc.id);
        if (isDuplicateCanonicalCity(city)) {
          final canonical = findCanonicalCityByName(name: city.cityName);
          if (canonical != null) {
            await _db.upsertCity(
              cityToCompanion(
                City(
                  cityId: doc.id,
                  cityName: canonical.cityName,
                ),
                syncStatus: aliasSynced,
              ),
            );
          }
          continue;
        }
        await _db.upsertCity(cityToCompanion(city));
      } catch (e) {
        debugPrint('Skip invalid city ${doc.id}: $e');
      }
    }
    for (final city in kCities) {
      await _db.upsertCity(cityToCompanion(city));
    }
  }

  Future<void> _pullAreas() async {
    final snapshot = await _firestore.collection('areas').get();
    if (snapshot.docs.isEmpty) {
      for (final city in kCities) {
        for (final area in areasForCity(city.cityId)) {
          await _db.upsertArea(areaToCompanion(area));
        }
      }
      return;
    }
    for (final doc in snapshot.docs) {
      try {
        final area = Area.fromMap(doc.data(), id: doc.id);
        final canonical = findCanonicalAreaMatch(area);
        if (canonical != null && canonical.areaId != area.areaId) {
          await _db.upsertArea(
            areaToCompanion(
              Area(
                areaId: doc.id,
                cityId: area.cityId,
                areaName: canonical.areaName,
                isMajor: canonical.isMajor,
              ),
              syncStatus: aliasSynced,
            ),
          );
          continue;
        }
        await _db.upsertArea(areaToCompanion(area));
      } catch (e) {
        debugPrint('Skip invalid area ${doc.id}: $e');
      }
    }
  }

  Future<UserSession?> _currentSession() async {
    final user = _auth.currentUser;
    if (user != null) {
      final local = await _localAuth.getUserByUid(user.uid);
      if (local != null) return local;
      final email = user.email;
      if (email != null) {
        return _localAuth.getUserByEmail(email);
      }
    }
    return _localAuth.getActiveOfflineSession();
  }
}
