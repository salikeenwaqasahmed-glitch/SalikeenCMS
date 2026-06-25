import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'reference_data.dart';

class SeedService {
  SeedService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _seedFlagDoc = 'meta/seeded';

  Future<void> seedIfNeeded() async {
    final flag = await _firestore.doc(_seedFlagDoc).get();
    if (flag.exists) return;

    final batch = _firestore.batch();

    for (final city in kCities) {
      batch.set(
        _firestore.collection('cities').doc(city.cityId),
        city.toMap(),
      );
    }
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
    await _ensureDemoUsers();
  }

  Future<void> _ensureDemoUsers() async {
    const adminEmail = 'admin@salikeen.com';
    const adminPassword = '12345678';

    final demos = [
      const _DemoUser(
        email: 'admin@salikeen.com',
        password: '12345678',
        name: 'Global Admin',
        role: 'admin',
        gender: 'Male',
      ),
      const _DemoUser(
        email: 'maleadmin@salikeen.com',
        password: '12345678',
        name: 'Male Gender Admin',
        role: 'genderAdmin',
        gender: 'Male',
      ),
      const _DemoUser(
        email: 'femaleadmin@salikeen.com',
        password: '12345678',
        name: 'Female Gender Admin',
        role: 'genderAdmin',
        gender: 'Female',
      ),
      const _DemoUser(
        email: 'maleeditor@salikeen.com',
        password: '12345678',
        name: 'Male Editor',
        role: 'editor',
        gender: 'Male',
      ),
      const _DemoUser(
        email: 'femaleeditor@salikeen.com',
        password: '12345678',
        name: 'Female Editor',
        role: 'editor',
        gender: 'Female',
      ),
    ];

    for (final demo in demos) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: demo.email,
          password: demo.password,
        );
        final uid = cred.user!.uid;
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        await _firestore.collection('users').doc(uid).set({
          'name': demo.name,
          'email': demo.email,
          'role': demo.role,
          'gender': demo.gender,
        });
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        final cred = await _auth.signInWithEmailAndPassword(
          email: demo.email,
          password: demo.password,
        );
        final uid = cred.user!.uid;
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        await _firestore.collection('users').doc(uid).set({
          'name': demo.name,
          'email': demo.email,
          'role': demo.role,
          'gender': demo.gender,
        }, SetOptions(merge: true));
      }
    }
  }
}

class _DemoUser {
  const _DemoUser({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.gender,
  });

  final String email;
  final String password;
  final String name;
  final String role;
  final String gender;
}
