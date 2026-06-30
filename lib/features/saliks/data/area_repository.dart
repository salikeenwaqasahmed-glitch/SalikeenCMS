import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/reference_data.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/entities/area.dart';
import '../domain/entities/city.dart';

final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(syncServiceProvider),
  );
});

class AreaRepository {
  AreaRepository(this._db, this._connectivity, this._sync);

  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final SyncService _sync;
  final _uuid = const Uuid();

  Stream<List<City>> watchCities() {
    return _db.watchCities().map((rows) {
      final cities = rows
          .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
          .map(
            (r) => City(
              cityId: r.cityId,
              cityName: r.cityName,
            ),
          )
          .toList()
        ..sort((a, b) => a.cityName.compareTo(b.cityName));
      if (cities.isEmpty) {
        return [...kCities]
          ..sort((a, b) => a.cityName.compareTo(b.cityName));
      }
      return cities;
    });
  }

  Stream<List<Area>> watchAreasByCity(String cityId) {
    return _db.watchAreasByCity(cityId).map((rows) {
      final areas = rows
          .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
          .map(
            (r) => Area(
              areaId: r.areaId,
              cityId: r.cityId,
              areaName: r.areaName,
              isMajor: r.isMajor,
            ),
          )
          .toList()
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
      if (areas.isNotEmpty) return areas;
      return areasForCity(cityId)
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
    });
  }

  Future<City?> resolveCity(String cityId) async {
    if (cityId.isEmpty) return null;

    final canonical = findCity(cityId);
    if (canonical != null) return canonical;

    final row = await _db.getCityById(cityId);
    if (row != null && row.syncStatus != pendingDelete) {
      return City(
        cityId: row.cityId,
        cityName: row.cityName,
      );
    }

    for (final city in await _allCities()) {
      if (city.cityId == cityId) return city;
    }
    return null;
  }

  Future<Area?> resolveArea(String areaId) async {
    if (areaId.isEmpty) return null;

    final canonical = findArea(areaId);
    if (canonical != null) return canonical;

    final row = await _db.getAreaById(areaId);
    if (row != null && row.syncStatus != pendingDelete) {
      return Area(
        areaId: row.areaId,
        cityId: row.cityId,
        areaName: row.areaName,
        isMajor: row.isMajor,
      );
    }
    return null;
  }

  Future<List<City>> _allCities() async {
    final rows = await _db.watchCities().first;
    if (rows.isEmpty) return kCities;
    return rows
        .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
        .map(
          (r) => City(
            cityId: r.cityId,
            cityName: r.cityName,
          ),
        )
        .toList();
  }

  Future<List<Area>> _areasForCityLocal(String cityId) async {
    final rows = await _db.watchAreasByCity(cityId).first;
    if (rows.isEmpty) return areasForCity(cityId);
    return rows
        .where((r) => r.syncStatus != pendingDelete && r.syncStatus != aliasSynced)
        .map(
          (r) => Area(
            areaId: r.areaId,
            cityId: r.cityId,
            areaName: r.areaName,
            isMajor: r.isMajor,
          ),
        )
        .toList();
  }

  Future<City?> findCityByName(String name) async {
    return findCityByNames(name: name);
  }

  Future<City?> findCityByNames({String name = ''}) async {
    final canonical = findCanonicalCityByName(name: name);
    if (canonical != null) {
      await _db.upsertCity(cityToCompanion(canonical));
      return canonical;
    }

    for (final city in await _allCities()) {
      if (cityMatchesNames(city, name: name)) {
        return city;
      }
    }
    return null;
  }

  Future<Area?> findAreaByName(String cityId, String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final area in await _areasForCityLocal(cityId)) {
      if (area.areaName.trim().toLowerCase() == normalized) {
        return area;
      }
    }
    return null;
  }

  Future<City> createCity({required String name}) async {
    final existing = await findCityByNames(name: name);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final city = City(
      cityId: id,
      cityName: name.trim(),
    );
    await _db.upsertCity(cityToCompanion(city, syncStatus: pendingCreate));
    await _db.enqueueSync(
      collection: 'cities',
      operation: 'create',
      docId: id,
      payload: city.toMap(),
    );
    if (await _connectivity.isOnline) {
      await _sync.syncNow();
    }
    return city;
  }

  Future<Area> createArea({
    required String cityId,
    required String name,
  }) async {
    final existing = await findAreaByName(cityId, name);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final area = Area(
      areaId: id,
      cityId: cityId,
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
      await _sync.syncNow();
    }
    return area;
  }
}
