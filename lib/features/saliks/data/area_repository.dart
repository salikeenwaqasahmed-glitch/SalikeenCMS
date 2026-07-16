import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/reference_data.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/entities/area.dart';

final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(syncServiceProvider),
    FirebaseFirestore.instance,
  );
});

class AreaRepository {
  AreaRepository(
    this._db,
    this._connectivity,
    this._sync,
    this._firestore,
  );

  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final SyncService _sync;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Stream<List<Area>> watchAreas() {
    return _db.watchAllAreas().map((rows) {
      final areas = rows
          .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
          .map(
            (r) => Area(
              areaId: r.areaId,
              areaName: r.areaName,
              isMajor: r.isMajor,
            ),
          )
          .toList()
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
      if (areas.isNotEmpty) return areas;
      return [...kAreas]
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
    });
  }

  Future<Area?> resolveArea(String areaId) async {
    if (areaId.isEmpty) return null;

    final canonical = findArea(areaId);
    if (canonical != null) return canonical;

    final row = await _db.getAreaById(areaId);
    if (row != null && row.syncStatus != pendingDelete) {
      return Area(
        areaId: row.areaId,
        areaName: row.areaName,
        isMajor: row.isMajor,
      );
    }

    return _fetchRemoteArea(areaId);
  }

  Future<Area?> _fetchRemoteArea(String areaId) async {
    if (!await _connectivity.isOnline) return null;
    try {
      final snap = await _firestore.collection('areas').doc(areaId).get();
      if (!snap.exists || snap.data() == null) return null;
      final area = Area.fromMap(snap.data()!, id: areaId);
      await _db.upsertArea(areaToCompanion(area, syncStatus: synced));
      return area;
    } catch (_) {
      return null;
    }
  }

  Future<List<Area>> _allAreasLocal() async {
    final rows = await _db.watchAllAreas().first;
    if (rows.isEmpty) return kAreas;
    return rows
        .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
        .map(
          (r) => Area(
            areaId: r.areaId,
            areaName: r.areaName,
            isMajor: r.isMajor,
          ),
        )
        .toList();
  }

  Future<Area?> findAreaByName(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final area in await _allAreasLocal()) {
      if (area.areaName.trim().toLowerCase() == normalized) {
        return area;
      }
    }
    return null;
  }

  Future<Area> createArea({
    required String name,
  }) async {
    final existing = await findAreaByName(name);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final area = Area(
      areaId: id,
      areaName: name.trim(),
    );
    await _db.upsertArea(areaToCompanion(area, syncStatus: pendingCreate));
    await _db.enqueueSync(
      collection: 'areas',
      operation: 'create',
      docId: id,
      payload: area.toMap(),
    );
    if (await _connectivity.isOnline) {
      unawaited(_sync.syncNow());
    }
    return area;
  }
}
