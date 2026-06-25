import '../data/reference_data.dart';
import '../database/app_database.dart';

/// Seeds reference cities and areas into local Drift when empty.
class LocalDataSeed {
  LocalDataSeed._();

  static Future<void> ensureReferenceData(AppDatabase db) async {
    final cityCount = await db.select(db.localCities).get();
    if (cityCount.isEmpty) {
      for (final city in kCities) {
        await db.upsertCity(cityToCompanion(city));
      }
    }

    final areaCount = await db.select(db.localAreas).get();
    if (areaCount.isEmpty) {
      for (final area in kAreas) {
        await db.upsertArea(areaToCompanion(area));
      }
    }
  }
}
