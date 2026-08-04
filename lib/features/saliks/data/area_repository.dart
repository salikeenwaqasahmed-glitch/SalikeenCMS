import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/reference_data.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/area.dart';
import '../domain/entities/bazam.dart';

final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepository(
    ref.watch(appDatabaseProvider),
  );
});

class AreaRepository {
  AreaRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  static Area _fromRow(LocalArea r) {
    final bazamId = r.bazamId.trim().isEmpty ? kDefaultBazamId : r.bazamId;
    return Area(
      areaId: r.areaId,
      areaName: r.areaName,
      bazamId: bazamId,
    );
  }

  Stream<List<Area>> watchAreas() {
    return _db.watchAllAreas().map((rows) {
      final areas = rows
          .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
          .map(_fromRow)
          .toList()
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
      if (areas.isNotEmpty) return areas;
      return [...kAreas]
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
    });
  }

  Stream<List<Bazam>> watchBazams() {
    return _db.watchAllBazams().map((rows) {
      final bazams = rows
          .where((r) => r.syncStatus != pendingDelete)
          .map(
            (r) => Bazam(
              bazamId: r.bazamId,
              bazamName: r.bazamName,
            ),
          )
          .toList()
        ..sort((a, b) => a.bazamName.compareTo(b.bazamName));
      if (bazams.isNotEmpty) return bazams;
      return [...kBazams];
    });
  }

  Future<Bazam?> resolveBazam(String bazamId) async {
    if (bazamId.isEmpty) return null;
    final canonical = findBazam(bazamId);
    if (canonical != null) return canonical;

    final row = await _db.getBazamById(bazamId);
    if (row != null && row.syncStatus != pendingDelete) {
      return Bazam(bazamId: row.bazamId, bazamName: row.bazamName);
    }
    return null;
  }

  Future<Area?> resolveArea(String areaId) async {
    if (areaId.isEmpty) return null;

    final canonical = findArea(areaId);
    if (canonical != null) return canonical;

    final row = await _db.getAreaById(areaId);
    if (row != null && row.syncStatus != pendingDelete) {
      return _fromRow(row);
    }

    return null;
  }

  Future<List<Area>> _allAreasLocal() async {
    final rows = await _db.watchAllAreas().first;
    if (rows.isEmpty) return kAreas;
    return rows
        .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
        .map(_fromRow)
        .toList();
  }

  Future<List<Area>> areasForBazam(String bazamId) async {
    final id = bazamId.trim().isEmpty ? kDefaultBazamId : bazamId.trim();
    final areas = await _allAreasLocal();
    return areas.where((a) => a.bazamId == id).toList()
      ..sort((a, b) => a.areaName.compareTo(b.areaName));
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
    String bazamId = kDefaultBazamId,
  }) async {
    final existing = await findAreaByName(name);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final area = Area(
      areaId: id,
      areaName: name.trim(),
      bazamId: bazamId.trim().isEmpty ? kDefaultBazamId : bazamId.trim(),
    );
    await _db.upsertArea(areaToCompanion(area, syncStatus: pendingCreate));
    await _db.enqueueSync(
      collection: 'areas',
      operation: 'create',
      docId: id,
      payload: area.toMap(),
    );
    return area;
  }
}
