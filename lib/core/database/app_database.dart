import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/saliks/domain/entities/approval_status.dart';
import '../../features/saliks/domain/entities/area.dart';
import '../../features/saliks/domain/entities/city.dart';
import '../../features/saliks/domain/entities/salik.dart';

part 'app_database.g.dart';

const synced = 'synced';
const pendingCreate = 'pendingCreate';
const pendingUpdate = 'pendingUpdate';
const pendingDelete = 'pendingDelete';
/// Lookup-only row mapping a remote doc id to canonical city/area names.
const aliasSynced = 'alias';

class LocalUsers extends Table {
  TextColumn get uid => text()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get gender => text()();
  TextColumn get passwordHash => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {uid};
}

class LocalSaliks extends Table {
  TextColumn get salikId => text()();
  TextColumn get nameEnglish => text()();
  TextColumn get nameUrdu => text()();
  TextColumn get fatherNameEnglish => text()();
  TextColumn get fatherNameUrdu => text()();
  TextColumn get mobileNumber => text()();
  TextColumn get whatsappNumber => text()();
  TextColumn get cityId => text()();
  TextColumn get areaId => text()();
  TextColumn get genderId => text()();
  TextColumn get bazamId => text().withDefault(const Constant(''))();
  TextColumn get khanqahId => text().withDefault(const Constant(''))();
  TextColumn get salikCategoryId => text().withDefault(const Constant(''))();
  TextColumn get dateOfBaith => text()();
  TextColumn get referenceName => text()();
  TextColumn get referenceMobile => text().withDefault(const Constant(''))();
  BoolColumn get isNafiAsbat => boolean().withDefault(const Constant(false))();
  BoolColumn get isSahibEMehfil =>
      boolean().withDefault(const Constant(false))();
  TextColumn get nafiZikrId => text().withDefault(const Constant(''))();
  TextColumn get profilePicture => text().withDefault(const Constant(''))();
  TextColumn get createdDate => text()();
  TextColumn get modifiedDate => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
  TextColumn get addedByUid => text().withDefault(const Constant(''))();
  TextColumn get addedByName => text().withDefault(const Constant(''))();
  TextColumn get approvalStatus =>
      text().withDefault(const Constant('approved'))();
  TextColumn get approvedByUid => text().withDefault(const Constant(''))();
  TextColumn get approvedByName => text().withDefault(const Constant(''))();
  TextColumn get approvedAt => text().withDefault(const Constant(''))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {salikId};
}

class LocalCities extends Table {
  TextColumn get cityId => text()();
  TextColumn get cityName => text()();
  TextColumn get cityNameUrdu => text()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {cityId};
}

class LocalAreas extends Table {
  TextColumn get areaId => text()();
  TextColumn get cityId => text()();
  TextColumn get areaName => text()();
  TextColumn get areaNameUrdu => text()();
  BoolColumn get isMajor => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {areaId};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collection => text()();
  TextColumn get operation => text()();
  TextColumn get docId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(tables: [LocalUsers, LocalSaliks, LocalCities, LocalAreas, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(localSaliks, localSaliks.addedByUid);
            await migrator.addColumn(localSaliks, localSaliks.addedByName);
          }
          if (from < 3) {
            await migrator.addColumn(localSaliks, localSaliks.approvalStatus);
            await migrator.addColumn(localSaliks, localSaliks.approvedByUid);
            await migrator.addColumn(localSaliks, localSaliks.approvedByName);
            await migrator.addColumn(localSaliks, localSaliks.approvedAt);
            await customStatement(
              "UPDATE local_saliks SET approval_status = 'approved' "
              "WHERE approval_status IS NULL OR approval_status = ''",
            );
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'salik_crm_local',
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            )
          : null,
    );
  }

  Stream<List<LocalSalik>> watchSaliks({
    String? genderFilter,
    String? approvalStatus,
    String? addedByUid,
  }) {
    final query = select(localSaliks)
      ..where(
        (t) => genderFilter == null
            ? const Constant(true)
            : t.genderId.equals(genderFilter),
      )
      ..where(
        (t) => approvalStatus == null
            ? const Constant(true)
            : t.approvalStatus.equals(approvalStatus),
      )
      ..where(
        (t) => addedByUid == null || addedByUid.isEmpty
            ? const Constant(true)
            : t.addedByUid.equals(addedByUid),
      )
      ..where((t) => t.syncStatus.isNotValue(pendingDelete));
    return query.watch();
  }

  Future<List<LocalSalik>> getAllSaliks({
    String? genderFilter,
    String? approvalStatus,
    String? addedByUid,
  }) {
    final query = select(localSaliks)
      ..where(
        (t) => genderFilter == null
            ? const Constant(true)
            : t.genderId.equals(genderFilter),
      )
      ..where(
        (t) => approvalStatus == null
            ? const Constant(true)
            : t.approvalStatus.equals(approvalStatus),
      )
      ..where(
        (t) => addedByUid == null || addedByUid.isEmpty
            ? const Constant(true)
            : t.addedByUid.equals(addedByUid),
      )
      ..where((t) => t.syncStatus.isNotValue(pendingDelete));
    return query.get();
  }

  Future<int> countSaliks({
    String? genderFilter,
    String? approvalStatus,
    String? addedByUid,
  }) async {
    final count = countAll();
    final query = selectOnly(localSaliks)..addColumns([count]);
    if (genderFilter != null) {
      query.where(localSaliks.genderId.equals(genderFilter));
    }
    if (approvalStatus != null) {
      query.where(localSaliks.approvalStatus.equals(approvalStatus));
    }
    if (addedByUid != null && addedByUid.isNotEmpty) {
      query.where(localSaliks.addedByUid.equals(addedByUid));
    }
    query.where(localSaliks.syncStatus.isNotValue(pendingDelete));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<LocalSalik?> getSalikById(String id) {
    return (select(localSaliks)..where((t) => t.salikId.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertSalik(LocalSaliksCompanion row) {
    return into(localSaliks).insertOnConflictUpdate(row);
  }

  Future<void> deleteSalikLocal(String id) {
    return (delete(localSaliks)..where((t) => t.salikId.equals(id))).go();
  }

  Stream<List<LocalCity>> watchCities() {
    return (select(localCities)
          ..orderBy([(t) => OrderingTerm.asc(t.cityName)]))
        .watch();
  }

  Stream<List<LocalArea>> watchAreasByCity(String cityId) {
    return (select(localAreas)
          ..where((t) => t.cityId.equals(cityId))
          ..orderBy([(t) => OrderingTerm.asc(t.areaName)]))
        .watch();
  }

  Future<void> upsertCity(LocalCitiesCompanion row) {
    return into(localCities).insertOnConflictUpdate(row);
  }

  Future<void> upsertArea(LocalAreasCompanion row) {
    return into(localAreas).insertOnConflictUpdate(row);
  }

  Future<LocalCity?> getCityById(String id) {
    return (select(localCities)..where((t) => t.cityId.equals(id)))
        .getSingleOrNull();
  }

  Future<LocalArea?> getAreaById(String id) {
    return (select(localAreas)..where((t) => t.areaId.equals(id)))
        .getSingleOrNull();
  }

  Future<List<LocalCity>> getAllCities() {
    return select(localCities).get();
  }

  Future<List<LocalArea>> getAllAreas() {
    return select(localAreas).get();
  }

  Future<LocalUser?> getUserByEmail(String email) {
    return (select(localUsers)..where((t) => t.email.equals(email)))
        .getSingleOrNull();
  }

  Future<LocalUser?> getUserByUid(String uid) {
    return (select(localUsers)..where((t) => t.uid.equals(uid)))
        .getSingleOrNull();
  }

  Future<void> upsertUser(LocalUsersCompanion row) {
    return into(localUsers).insertOnConflictUpdate(row);
  }

  Future<int> enqueueSync({
    required String collection,
    required String operation,
    required String docId,
    required Map<String, dynamic> payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        collection: collection,
        operation: operation,
        docId: docId,
        payloadJson: jsonEncode(payload),
      ),
    );
  }

  Future<List<SyncQueueData>> pendingSyncItems() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  }

  Future<int> pendingSyncCount() async {
    final count = countAll();
    final query = selectOnly(syncQueue)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> removeSyncItem(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> syncQueueItemExists(int id) async {
    final row = await (select(syncQueue)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> removeSyncItemsForDoc(String collection, String docId) {
    return (delete(syncQueue)
          ..where((t) => t.collection.equals(collection))
          ..where((t) => t.docId.equals(docId)))
        .go();
  }

  Future<void> updateSyncError(int id, String error, int retryCount) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(retryCount),
        lastError: Value(error),
      ),
    );
  }
}

extension LocalSalikMapper on LocalSalik {
  Salik toSalik() {
    return Salik(
      salikId: salikId,
      nameEnglish: nameEnglish,
      nameUrdu: nameUrdu,
      fatherNameEnglish: fatherNameEnglish,
      fatherNameUrdu: fatherNameUrdu,
      mobileNumber: mobileNumber,
      whatsappNumber: whatsappNumber,
      cityId: cityId,
      areaId: areaId,
      genderId: genderId,
      bazamId: bazamId,
      khanqahId: khanqahId,
      salikCategoryId: salikCategoryId,
      dateOfBaith: dateOfBaith,
      referenceName: referenceName,
      referenceMobile: referenceMobile,
      isNafiAsbat: isNafiAsbat,
      isSahibEMehfil: isSahibEMehfil,
      nafiZikrId: nafiZikrId,
      profilePicture: profilePicture,
      createdDate: createdDate,
      modifiedDate: modifiedDate,
      isActive: isActive,
      notes: notes,
      addedByUid: addedByUid,
      addedByName: addedByName,
      approvalStatus: ApprovalStatus.fromString(approvalStatus),
      approvedByUid: approvedByUid,
      approvedByName: approvedByName,
      approvedAt: approvedAt,
    );
  }
}

LocalSaliksCompanion salikToCompanion(Salik salik, {required String syncStatus}) {
  return LocalSaliksCompanion(
    salikId: Value(salik.salikId),
    nameEnglish: Value(salik.nameEnglish),
    nameUrdu: Value(salik.nameUrdu),
    fatherNameEnglish: Value(salik.fatherNameEnglish),
    fatherNameUrdu: Value(salik.fatherNameUrdu),
    mobileNumber: Value(salik.mobileNumber),
    whatsappNumber: Value(salik.whatsappNumber),
    cityId: Value(salik.cityId),
    areaId: Value(salik.areaId),
    genderId: Value(salik.genderId),
    bazamId: Value(salik.bazamId),
    khanqahId: Value(salik.khanqahId),
    salikCategoryId: Value(salik.salikCategoryId),
    dateOfBaith: Value(salik.dateOfBaith),
    referenceName: Value(salik.referenceName),
    referenceMobile: Value(salik.referenceMobile),
    isNafiAsbat: Value(salik.isNafiAsbat),
    isSahibEMehfil: Value(salik.isSahibEMehfil),
    nafiZikrId: Value(salik.nafiZikrId),
    profilePicture: Value(salik.profilePicture),
    createdDate: Value(salik.createdDate),
    modifiedDate: Value(salik.modifiedDate),
    isActive: Value(salik.isActive),
    notes: Value(salik.notes),
    addedByUid: Value(salik.addedByUid),
    addedByName: Value(salik.addedByName),
    approvalStatus: Value(salik.approvalStatus.toFirestore()),
    approvedByUid: Value(salik.approvedByUid),
    approvedByName: Value(salik.approvedByName),
    approvedAt: Value(salik.approvedAt),
    syncStatus: Value(syncStatus),
    localUpdatedAt: Value(DateTime.now()),
  );
}

LocalCitiesCompanion cityToCompanion(City city, {String syncStatus = synced}) {
  return LocalCitiesCompanion(
    cityId: Value(city.cityId),
    cityName: Value(city.cityName),
    cityNameUrdu: Value(city.cityNameUrdu),
    syncStatus: Value(syncStatus),
  );
}

LocalAreasCompanion areaToCompanion(Area area, {String syncStatus = synced}) {
  return LocalAreasCompanion(
    areaId: Value(area.areaId),
    cityId: Value(area.cityId),
    areaName: Value(area.areaName),
    areaNameUrdu: Value(area.areaNameUrdu),
    isMajor: Value(area.isMajor),
    syncStatus: Value(syncStatus),
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
