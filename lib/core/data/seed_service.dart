import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../auth/seed_credentials.dart';
import '../auth/staff_users.dart';
import 'reference_data.dart';

class SeedService {
  SeedService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _seedFlagDoc = 'meta/seeded';
  static const _staffFlagDoc = 'meta/staffProvisioned';

  Future<void> seedIfNeeded() async {
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

  /// Idempotent: create or merge Firebase Auth + Firestore users/{uid} for all staff.
  ///
  /// Each Firestore profile is written while signed in as that user (rules allow
  /// self create on users/{uid}). Caller session is restored at the end.
  Future<void> ensureStaffUsers({
    String? restoreEmail,
    String? restorePassword,
  }) async {
    final adminEmail = restoreEmail ??
        _auth.currentUser?.email ??
        kBootstrapAdminEmail;
    final adminPassword = restorePassword ?? SeedCredentials.defaultPassword;

    final flag = await _firestore.doc(_staffFlagDoc).get();
    if (flag.exists || await _allStaffProfilesExist()) {
      if (!flag.exists) {
        await _firestore.doc(_staffFlagDoc).set({
          'provisionedAt': FieldValue.serverTimestamp(),
        });
      }
      await _restoreAdminSession(adminEmail, adminPassword);
      return;
    }

    for (final staff in kStaffUsers) {
      try {
        await _provisionStaffAuthAndProfile(staff, adminPassword);
        // createUser/signIn leaves Auth on this staff — restore admin before next.
        await _restoreAdminSession(adminEmail, adminPassword);
      } catch (e, st) {
        debugPrint('ensureStaffUsers failed for ${staff.email}: $e\n$st');
        await _restoreAdminSession(adminEmail, adminPassword);
        rethrow;
      }
    }

    await _firestore.doc(_staffFlagDoc).set({
      'provisionedAt': FieldValue.serverTimestamp(),
    });
    await _restoreAdminSession(adminEmail, adminPassword);
  }

  Future<bool> _allStaffProfilesExist() async {
    for (final staff in kStaffUsers) {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: staff.email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return false;
    }
    return true;
  }

  Future<void> _restoreAdminSession(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final current = _auth.currentUser?.email?.trim().toLowerCase();
    if (current == normalized) return;

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('ensureStaffUsers: could not restore $email session: $e');
    }
  }

  Future<void> _provisionStaffAuthAndProfile(
    StaffUser staff,
    String password,
  ) async {
    final profile = {
      'name': staff.name,
      'email': staff.email,
      'role': staff.role.toFirestore(),
      'gender': staff.gender,
    };

    try {
      await _auth.createUserWithEmailAndPassword(
        email: staff.email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      await _auth.signInWithEmailAndPassword(
        email: staff.email,
        password: password,
      );
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No Firebase user after provisioning ${staff.email}');
    }

    await _firestore.collection('users').doc(uid).set(
          profile,
          SetOptions(merge: true),
        );
  }
}
