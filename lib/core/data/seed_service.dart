import 'package:cloud_firestore/cloud_firestore.dart';

import 'reference_data.dart';

/// Seeds reference bazams + areas into Firestore (admin post-login).
class SeedService {
  SeedService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _seedFlagDoc = 'meta/seeded';
  static const _bazamsSeedFlagDoc = 'meta/bazamsSeeded';

  Future<void> seedIfNeeded() async {
    await _seedAreasIfNeeded();
    await _seedBazamsIfNeeded();
  }

  Future<void> _seedAreasIfNeeded() async {
    final flag = await _firestore.doc(_seedFlagDoc).get();
    if (flag.exists) return;

    final batch = _firestore.batch();

    for (final area in kAreas) {
      batch.set(
        _firestore.collection('areas').doc(area.areaId),
        area.toMap(),
      );
    }

    batch.set(_firestore.doc(_seedFlagDoc), {
      'seededAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Always upserts default bazams + area.bazamId (merge). Safe for existing installs.
  Future<void> _seedBazamsIfNeeded() async {
    final batch = _firestore.batch();

    for (final bazam in kBazams) {
      batch.set(
        _firestore.collection('bazams').doc(bazam.bazamId),
        bazam.toMap(),
        SetOptions(merge: true),
      );
    }

    for (final area in kAreas) {
      batch.set(
        _firestore.collection('areas').doc(area.areaId),
        {'bazamId': area.bazamId},
        SetOptions(merge: true),
      );
    }

    batch.set(_firestore.doc(_bazamsSeedFlagDoc), {
      'seededAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
