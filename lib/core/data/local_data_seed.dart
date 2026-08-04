import '../data/reference_data.dart';
import '../database/app_database.dart';

/// Seeds reference bazams + areas into local Drift when missing.
class LocalDataSeed {
  LocalDataSeed._();

  static Future<void> ensureReferenceData(AppDatabase db) async {
    for (final bazam in kBazams) {
      await db.upsertBazam(bazamToCompanion(bazam));
    }
    for (final area in kAreas) {
      await db.upsertArea(areaToCompanion(area));
    }
  }
}
