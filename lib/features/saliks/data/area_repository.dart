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
          .where((r) => r.syncStatus != pendingDelete)
          .map(
            (r) => City(
              cityId: r.cityId,
              cityName: r.cityName,
              cityNameUrdu: r.cityNameUrdu,
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
          .where((r) => r.syncStatus != pendingDelete)
          .map(
            (r) => Area(
              areaId: r.areaId,
              cityId: r.cityId,
              areaName: r.areaName,
              areaNameUrdu: r.areaNameUrdu,
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

  Future<List<City>> _allCities() async {
    final rows = await _db.watchCities().first;
    if (rows.isEmpty) return kCities;
    return rows
        .where((r) => r.syncStatus != pendingDelete)
        .map(
          (r) => City(
            cityId: r.cityId,
            cityName: r.cityName,
            cityNameUrdu: r.cityNameUrdu,
          ),
        )
        .toList();
  }

  Future<List<Area>> _areasForCityLocal(String cityId) async {
    final rows = await _db.watchAreasByCity(cityId).first;
    if (rows.isEmpty) return areasForCity(cityId);
    return rows
        .where((r) => r.syncStatus != pendingDelete)
        .map(
          (r) => Area(
            areaId: r.areaId,
            cityId: r.cityId,
            areaName: r.areaName,
            areaNameUrdu: r.areaNameUrdu,
            isMajor: r.isMajor,
          ),
        )
        .toList();
  }

  Future<City?> findCityByName(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final city in await _allCities()) {
      if (city.cityName.toLowerCase() == normalized ||
          city.cityNameUrdu.toLowerCase() == normalized) {
        return city;
      }
    }
    return null;
  }

  Future<Area?> findAreaByName(String cityId, String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final area in await _areasForCityLocal(cityId)) {
      if (area.areaName.toLowerCase() == normalized ||
          area.areaNameUrdu.toLowerCase() == normalized) {
        return area;
      }
    }
    return null;
  }

  Future<City> createCity({
    required String nameEn,
    required String nameUr,
  }) async {
    final existing = await findCityByName(nameEn.isNotEmpty ? nameEn : nameUr);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final city = City(
      cityId: id,
      cityName: nameEn,
      cityNameUrdu: nameUr,
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
    required String nameEn,
    required String nameUr,
  }) async {
    final existing = await findAreaByName(
      cityId,
      nameEn.isNotEmpty ? nameEn : nameUr,
    );
    if (existing != null) return existing;

    final id = _uuid.v4();
    final area = Area(
      areaId: id,
      cityId: cityId,
      areaName: nameEn,
      areaNameUrdu: nameUr,
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
