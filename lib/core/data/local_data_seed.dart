import '../data/reference_data.dart';
import '../database/app_database.dart';

/// Seeds reference cities and areas into local Drift when missing.
class LocalDataSeed {
  LocalDataSeed._();

  static Future<void> ensureReferenceData(AppDatabase db) async {
    for (final city in kCities) {
      await db.upsertCity(cityToCompanion(city));
    }

    for (final area in kAreas) {
      await db.upsertArea(areaToCompanion(area));
    }
  }
}
