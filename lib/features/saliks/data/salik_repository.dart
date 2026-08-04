import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/local_auth_store.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/access_control.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_session.dart';
import '../domain/entities/approval_status.dart';
import '../domain/entities/duplicate_salik_reason.dart';
import '../domain/entities/salik.dart';
import '../../../core/utils/stream_debounce.dart';
import '../domain/entities/salik_duplicate_group.dart';
import 'duplicate_salik_logic.dart';
import 'salik_list_streams.dart';

class SalikPermissionException implements Exception {
  SalikPermissionException(this.message);

  final String message;
}

final salikRepositoryProvider = Provider<SalikRepository>((ref) {
  return SalikRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(authRepositoryProvider),
    FirebaseFirestore.instance,
  );
});

class SalikRepository {
  SalikRepository(
    this._db,
    this._connectivity,
    this._auth,
    this._firestore,
  );

  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final AuthRepository _auth;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  static String normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String normalizeEnglish(String value) => value.trim().toLowerCase();

  static String normalizeUrdu(String value) => value.trim();

  static bool editorOwnsSalik(Salik salik, UserSession session) {
    final email = LocalAuthStore.normalizeEmail(session.email);
    final localUid = 'local-$email';
    if (salik.addedByUid == session.uid || salik.addedByUid == localUid) {
      return true;
    }
    final addedByName = salik.addedByName.trim();
    return addedByName.isNotEmpty && addedByName == session.name.trim();
  }

  List<Salik> _localSaliksFromRows(
    List<LocalSalik> localRows, {
    required bool Function(Salik salik) include,
  }) {
    return mergeSalikOutbox(
      remote: const [],
      localRows: localRows,
      includeRemote: include,
      includeLocal: include,
      includeSyncedLocal: true,
    );
  }

  Stream<List<Salik>> watchEditorDirectorySaliks(UserSession session) {
    final gender = AccessControl.genderFilter(session);
    bool include(Salik salik) =>
        salik.isApproved ||
        (salik.isPending && editorOwnsSalik(salik, session));

    return watchLocalSaliks(
      localStream: _db.watchSaliks(genderFilter: gender),
      project: (local) {
        final saliks = _localSaliksFromRows(local, include: include)
          ..sort((a, b) {
            if (a.isPending == b.isPending) return 0;
            return a.isPending ? -1 : 1;
          });
        return saliks;
      },
    );
  }

  /// genderAdmin / admin: approved saliks in session gender scope (all genders for admin).
  Stream<List<Salik>> watchGenderScopedSaliks(UserSession? session) =>
      watchApprovedSaliks(session);

  Stream<List<Salik>> watchApprovedSaliks(UserSession? session) {
    final gender = AccessControl.genderFilter(session);
    bool include(Salik salik) => salik.isApproved;

    return watchLocalSaliks(
      localStream: _db.watchSaliks(genderFilter: gender),
      project: (local) => _localSaliksFromRows(local, include: include),
    );
  }

  Stream<List<Salik>> watchPendingSaliks(UserSession? session) {
    if (session == null || !AccessControl.canViewPending(session.role)) {
      return Stream.value([]);
    }

    final gender = AccessControl.genderFilter(session);

    if (AccessControl.isEditor(session.role)) {
      bool include(Salik salik) =>
          (salik.isPending || salik.isRejected) &&
          editorOwnsSalik(salik, session);

      return watchLocalSaliks(
        localStream: _db.watchSaliks(genderFilter: gender),
        project: (local) => _localSaliksFromRows(local, include: include),
      );
    }

    bool include(Salik salik) => salik.isPending;

    return watchLocalSaliks(
      localStream: _db.watchSaliks(
        genderFilter: gender,
        approvalStatus: ApprovalStatus.pending.toFirestore(),
      ),
      project: (local) => _localSaliksFromRows(local, include: include),
    );
  }

  Stream<List<Salik>> watchSaliks(UserSession? session) =>
      watchApprovedSaliks(session);

  Future<int> pendingCount(UserSession? session) async {
    if (session == null || !AccessControl.canViewPending(session.role)) {
      return 0;
    }
    final pending = await watchPendingSaliks(session).first;
    return pending.where((s) => s.isPending).length;
  }

  Future<Salik?> getSalik(String id) => resolveSalik(id);

  Future<Salik?> resolveSalik(String id) async {
    final row = await _db.getSalikById(id);
    if (row != null && row.syncStatus != pendingDelete) {
      return row.toSalik();
    }

    if (!await _connectivity.isOnline ||
        FirebaseAuth.instance.currentUser == null) {
      return null;
    }

    return _fetchRemoteSalik(id, cache: true);
  }

  Future<({Salik salik, String syncStatus})?> resolveSalikWithStatus(
    String id,
  ) async {
    final row = await _db.getSalikById(id);
    final hasPendingLocal = row != null && row.syncStatus != synced;

    if (await _connectivity.isOnline &&
        FirebaseAuth.instance.currentUser != null) {
      final remote = await _fetchRemoteSalik(id, cache: !hasPendingLocal);
      if (remote != null && !hasPendingLocal) {
        return (salik: remote, syncStatus: synced);
      }
    }

    if (row != null) {
      return (salik: row.toSalik(), syncStatus: row.syncStatus);
    }

    final remote = await _fetchRemoteSalik(id);
    if (remote == null) return null;
    return (salik: remote, syncStatus: synced);
  }

  Future<Salik?> _fetchRemoteSalik(String id, {bool cache = true}) async {
    if (!await _connectivity.isOnline) return null;
    if (FirebaseAuth.instance.currentUser == null) return null;
    try {
      final snap = await _firestore.collection('saliks').doc(id).get();
      if (!snap.exists) return null;
      final salik = Salik.fromMap(snap.data()!, id: id);
      if (cache) {
        await _db.upsertSalik(salikToCompanion(salik, syncStatus: synced));
      }
      return salik;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureLocalOutboxFromRemote(String id) async {
    final row = await _db.getSalikById(id);
    if (row != null) return;
    final remote = await _fetchRemoteSalik(id);
    if (remote == null) return;
    await _db.upsertSalik(
      salikToCompanion(remote, syncStatus: pendingUpdate),
    );
  }

  Future<List<Salik>> _approvedSaliksInScope(UserSession? session) async {
    final gender = AccessControl.genderFilter(session);
    final rows = await _db.getAllSaliks(
      genderFilter: gender,
      approvalStatus: ApprovalStatus.approved.toFirestore(),
    );
    return mergeSalikOutbox(
      remote: const [],
      localRows: rows,
      includeLocal: (s) => s.isApproved,
      includeSyncedLocal: true,
    );
  }

  Future<DuplicateSalikReason?> findDuplicate({
    required Salik candidate,
    UserSession? session,
    String? excludeSalikId,
    bool approvedOnly = true,
  }) async {
    final mobile = normalizePhone(candidate.mobileNumber);
    final name = normalizeEnglish(candidate.name);
    final father = normalizeEnglish(candidate.fatherName);
    final checkName = name.isNotEmpty && father.isNotEmpty;

    final rows = approvedOnly
        ? await _approvedSaliksInScope(session)
        : mergeSalikOutbox(
            remote: const [],
            localRows: await _db.getAllSaliks(
              genderFilter: AccessControl.genderFilter(session),
            ),
            includeSyncedLocal: true,
          );
    for (final salik in rows) {
      if (excludeSalikId != null && salik.salikId == excludeSalikId) continue;

      if (mobile.isNotEmpty && normalizePhone(salik.mobileNumber) == mobile) {
        return DuplicateSalikReason.mobile;
      }

      if (checkName) {
        final existingName = normalizeEnglish(salik.name);
        final existingFather = normalizeEnglish(salik.fatherName);
        if (existingName == name && existingFather == father) {
          return DuplicateSalikReason.name;
        }
      }
    }
    return null;
  }

  Future<String> createSalik(Salik salik, {UserSession? session}) async {
    if (session != null && !AccessControl.canCreate(session.role)) {
      throw SalikPermissionException('Cannot create salik');
    }

    final duplicate = await findDuplicate(
      candidate: salik,
      session: session,
      approvedOnly: true,
    );
    if (duplicate != null) {
      throw DuplicateSalikException(duplicate);
    }

    final id = salik.salikId.isNotEmpty ? salik.salikId : _uuid.v4();
    final creatorName = session == null
        ? salik.addedByName
        : session.name.trim().isNotEmpty
            ? session.name.trim()
            : await _auth.resolveUserDisplayName(
                session.uid,
                fallback: session.name,
              );

    final isEditor = session != null && AccessControl.isEditor(session.role);
    final saved = salik.copyWith(
      salikId: id,
      addedByUid: session?.uid ?? salik.addedByUid,
      addedByName: creatorName,
      approvalStatus: isEditor
          ? ApprovalStatus.pending
          : ApprovalStatus.approved,
      isActive: !isEditor,
      approvedByUid: isEditor ? '' : (session?.uid ?? ''),
      approvedByName: isEditor ? '' : creatorName,
      approvedAt: isEditor
          ? ''
          : DateTime.now().toIso8601String(),
    );

    await _persistSalik(saved, syncStatus: pendingCreate);
    return id;
  }

  Future<void> updateSalik(Salik salik, {UserSession? session}) async {
    if (session != null && !AccessControl.canUpdate(session.role)) {
      throw SalikPermissionException('Cannot update salik');
    }

    await _ensureLocalOutboxFromRemote(salik.salikId);
    final existing = await _db.getSalikById(salik.salikId);
    if (existing == null) return;

    if (existing.approvalStatus == ApprovalStatus.pending.toFirestore() &&
        session != null &&
        !AccessControl.canApprove(session.role)) {
      throw SalikPermissionException('Cannot edit pending salik');
    }

    final duplicate = await findDuplicate(
      candidate: salik,
      session: session,
      excludeSalikId: salik.salikId,
      approvedOnly: true,
    );
    if (duplicate != null) {
      throw DuplicateSalikException(duplicate);
    }

    final status =
        existing.syncStatus == pendingCreate ? pendingCreate : pendingUpdate;

    final preserved = salik.copyWith(
      addedByUid: existing.addedByUid,
      addedByName: existing.addedByName,
      approvalStatus: ApprovalStatus.fromString(existing.approvalStatus),
      approvedByUid: existing.approvedByUid,
      approvedByName: existing.approvedByName,
      approvedAt: existing.approvedAt,
    );

    await _persistSalik(preserved, syncStatus: status);
  }

  Future<void> approveSalik(String id, {required UserSession session}) async {
    if (!AccessControl.canApprove(session.role)) {
      throw SalikPermissionException('Cannot approve salik');
    }

    final resolved = await resolveSalikWithStatus(id);
    if (resolved == null) {
      throw SalikPermissionException('Salik not found — refresh pending list');
    }

    if (resolved.salik.approvalStatus != ApprovalStatus.pending) {
      throw SalikPermissionException('Salik is not pending');
    }

    final gender = AccessControl.genderFilter(session);
    if (gender != null && resolved.salik.genderId != gender) {
      throw SalikPermissionException('Gender scope mismatch');
    }

    final salik = resolved.salik;
    final duplicate = await findDuplicate(
      candidate: salik,
      session: session,
      excludeSalikId: id,
      approvedOnly: true,
    );
    if (duplicate != null) {
      throw DuplicateSalikException(duplicate);
    }

    final approverName = _nonEmptyDisplayName(
      await _auth.resolveUserDisplayName(
        session.uid,
        fallback: session.name,
      ),
      session,
    );
    final approved = salik.copyWith(
      approvalStatus: ApprovalStatus.approved,
      isActive: true,
      approvedByUid: session.uid,
      approvedByName: approverName,
      approvedAt: DateTime.now().toIso8601String(),
      modifiedDate: DateTime.now().toIso8601String().split('T').first,
    );

    final wasNeverSynced = resolved.syncStatus == pendingCreate;
    final syncStatus = wasNeverSynced ? pendingCreate : pendingUpdate;
    final operation = wasNeverSynced ? 'create' : 'update';

    if (await _db.getSalikById(id) == null) {
      await _db.upsertSalik(
        salikToCompanion(salik, syncStatus: pendingUpdate),
      );
    }

    await _db.removeSyncItemsForDoc('saliks', id);
    await _db.upsertSalik(salikToCompanion(approved, syncStatus: syncStatus));
    await _db.enqueueSync(
      collection: 'saliks',
      operation: operation,
      docId: id,
      payload: approved.toMap(),
    );
    await _ensureApprovalPersisted(id, approved);
  }

  static String _nonEmptyDisplayName(String resolved, UserSession session) {
    final name = resolved.trim();
    if (name.isNotEmpty) return name;
    final sessionName = session.name.trim();
    if (sessionName.isNotEmpty) return sessionName;
    final email = LocalAuthStore.normalizeEmail(session.email);
    final localPart = email.split('@').first;
    return localPart.isNotEmpty ? localPart : 'Approver';
  }

  /// Re-apply approval if sync accidentally reverted local row to pending.
  Future<void> _ensureApprovalPersisted(String id, Salik approved) async {
    final row = await _db.getSalikById(id);
    if (row == null) return;

    if (row.toSalik().isPending && approved.isApproved) {
      final syncStatus = row.syncStatus == synced ? synced : row.syncStatus;
      await _db.upsertSalik(
        salikToCompanion(approved, syncStatus: syncStatus),
      );
      if (syncStatus == synced) {
        await _db.removeSyncItemsForDoc('saliks', id);
      }
      return;
    }

    if (row.syncStatus == synced) {
      await _db.removeSyncItemsForDoc('saliks', id);
    }
  }

  Future<void> rejectSalik(String id, {required UserSession session}) async {
    if (!AccessControl.canApprove(session.role)) {
      throw SalikPermissionException('Cannot reject salik');
    }

    final resolved = await resolveSalikWithStatus(id);
    if (resolved == null) {
      throw SalikPermissionException('Salik not found — refresh pending list');
    }

    if (resolved.salik.approvalStatus != ApprovalStatus.pending) {
      throw SalikPermissionException('Salik is not pending');
    }

    final gender = AccessControl.genderFilter(session);
    if (gender != null && resolved.salik.genderId != gender) {
      throw SalikPermissionException('Gender scope mismatch');
    }

    final approverName = _nonEmptyDisplayName(
      await _auth.resolveUserDisplayName(
        session.uid,
        fallback: session.name,
      ),
      session,
    );
    final rejected = resolved.salik.copyWith(
          approvalStatus: ApprovalStatus.rejected,
          isActive: false,
          approvedByUid: session.uid,
          approvedByName: approverName,
          approvedAt: DateTime.now().toIso8601String(),
          modifiedDate: DateTime.now().toIso8601String().split('T').first,
        );

    final wasNeverSynced = resolved.syncStatus == pendingCreate;
    final syncStatus = wasNeverSynced ? pendingCreate : pendingUpdate;
    final operation = wasNeverSynced ? 'create' : 'update';

    if (await _db.getSalikById(id) == null) {
      await _db.upsertSalik(
        salikToCompanion(resolved.salik, syncStatus: pendingUpdate),
      );
    }

    await _db.removeSyncItemsForDoc('saliks', id);
    await _db.upsertSalik(salikToCompanion(rejected, syncStatus: syncStatus));
    await _db.enqueueSync(
      collection: 'saliks',
      operation: operation,
      docId: id,
      payload: rejected.toMap(),
    );
    await _ensureRejectionPersisted(id, rejected);
  }

  Future<void> _ensureRejectionPersisted(String id, Salik rejected) async {
    final row = await _db.getSalikById(id);
    if (row == null) return;

    if (row.toSalik().isPending && rejected.isRejected) {
      final syncStatus = row.syncStatus == synced ? synced : row.syncStatus;
      await _db.upsertSalik(
        salikToCompanion(rejected, syncStatus: syncStatus),
      );
      if (syncStatus == synced) {
        await _db.removeSyncItemsForDoc('saliks', id);
      }
      return;
    }

    if (row.syncStatus == synced) {
      await _db.removeSyncItemsForDoc('saliks', id);
    }
  }

  Future<void> deleteSalik(
    String id, {
    UserSession? session,
    bool duplicateCleanup = false,
  }) async {
    if (session != null) {
      final allowed = duplicateCleanup
          ? AccessControl.canResolveDuplicates(session.role)
          : AccessControl.canDelete(session.role);
      if (!allowed) {
        throw SalikPermissionException('Cannot delete salik');
      }
      if (duplicateCleanup) {
        final salik = await resolveSalik(id);
        final gender = AccessControl.genderFilter(session);
        if (salik != null && gender != null && salik.genderId != gender) {
          throw SalikPermissionException('Gender scope mismatch');
        }
      }
    }

    var existing = await _db.getSalikById(id);
    if (existing == null) {
      await _ensureLocalOutboxFromRemote(id);
      existing = await _db.getSalikById(id);
      if (existing == null) return;
    }

    if (existing.syncStatus == pendingCreate) {
      await _db.deleteSalikLocal(id);
      await _db.removeSyncItemsForDoc('saliks', id);
      return;
    }

    await _db.upsertSalik(
      salikToCompanion(existing.toSalik(), syncStatus: pendingDelete),
    );
    await _db.enqueueSync(
      collection: 'saliks',
      operation: 'delete',
      docId: id,
      payload: {'salikId': id},
    );
  }

  Future<void> toggleActive(String id, bool isActive,
      {UserSession? session}) async {
    if (session != null && !AccessControl.canUpdate(session.role)) {
      throw SalikPermissionException('Cannot update salik');
    }

    await _ensureLocalOutboxFromRemote(id);
    final existing = await _db.getSalikById(id);
    if (existing == null) return;

    if (existing.approvalStatus != ApprovalStatus.approved.toFirestore()) {
      throw SalikPermissionException('Cannot toggle inactive pending salik');
    }

    final updated = existing.toSalik().copyWith(
          isActive: isActive,
          modifiedDate: DateTime.now().toIso8601String().split('T').first,
        );
    await updateSalik(updated, session: session);
  }

  Stream<List<SalikDuplicateGroup>> watchDuplicateGroups(UserSession? session) {
    if (session == null || !AccessControl.canResolveDuplicates(session.role)) {
      return Stream.value([]);
    }
    return debounceStream(
      watchAllSaliksInScope(session),
      const Duration(milliseconds: 400),
    ).map(findSalikDuplicateGroups);
  }

  Stream<List<Salik>> watchAllSaliksInScope(UserSession session) {
    final gender = AccessControl.genderFilter(session);
    bool include(Salik salik) => !salik.isRejected;

    return watchLocalSaliks(
      localStream: _db.watchSaliks(genderFilter: gender),
      project: (local) => _localSaliksFromRows(local, include: include),
    );
  }

  Future<void> mergeDuplicateSaliks({
    required UserSession session,
    required String keepSalikId,
    required List<String> removeSalikIds,
  }) async {
    if (!AccessControl.canResolveDuplicates(session.role)) {
      throw SalikPermissionException('Cannot resolve duplicates');
    }

    final keeper = await resolveSalik(keepSalikId);
    if (keeper == null) {
      throw SalikPermissionException('Salik not found');
    }

    final gender = AccessControl.genderFilter(session);
    if (gender != null && keeper.genderId != gender) {
      throw SalikPermissionException('Gender scope mismatch');
    }

    var merged = keeper;
    final toRemove = <String>{};
    for (final id in removeSalikIds) {
      if (id == keepSalikId) continue;
      final other = await resolveSalik(id);
      if (other == null) continue;
      if (gender != null && other.genderId != gender) continue;
      merged = mergeSalikRecords(merged, other);
      toRemove.add(id);
    }

    if (toRemove.isEmpty) return;

    await updateSalik(merged, session: session);
    for (final id in toRemove) {
      await deleteSalik(id, session: session, duplicateCleanup: true);
    }
  }

  Future<void> _persistSalik(Salik salik, {required String syncStatus}) async {
    await _db.removeSyncItemsForDoc('saliks', salik.salikId);
    await _db.upsertSalik(salikToCompanion(salik, syncStatus: syncStatus));
    await _db.enqueueSync(
      collection: 'saliks',
      operation: syncStatus == pendingCreate ? 'create' : 'update',
      docId: salik.salikId,
      payload: salik.toMap(),
    );
  }
}
