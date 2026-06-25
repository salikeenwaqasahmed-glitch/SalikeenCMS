import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/core/database/app_database.dart';
import 'package:salik_management_system/core/utils/access_control.dart';
import 'package:salik_management_system/features/auth/domain/user_role.dart';
import 'package:salik_management_system/features/auth/domain/user_session.dart';
import 'package:salik_management_system/features/saliks/data/salik_list_streams.dart';
import 'package:salik_management_system/features/saliks/domain/entities/approval_status.dart';
import 'package:salik_management_system/features/saliks/domain/entities/salik.dart';
import 'package:salik_management_system/features/saliks/presentation/providers/salik_provider.dart';

void main() {
  group('approval workflow', () {
    test('editor role has create-only access', () {
      expect(AccessControl.canCreate(UserRole.editor), isTrue);
      expect(AccessControl.canUpdate(UserRole.editor), isFalse);
      expect(AccessControl.canDelete(UserRole.editor), isFalse);
      expect(AccessControl.canApprove(UserRole.editor), isFalse);
      expect(AccessControl.canViewPending(UserRole.editor), isTrue);
    });

    test('genderAdmin can approve and CRUD', () {
      expect(AccessControl.canApprove(UserRole.genderAdmin), isTrue);
      expect(AccessControl.canUpdate(UserRole.genderAdmin), isTrue);
      expect(AccessControl.canDelete(UserRole.genderAdmin), isTrue);
    });

    test('crudUser maps to editor permissions via fromString', () {
      expect(UserRole.fromString('crudUser'), UserRole.editor);
      expect(UserRole.fromString('editor'), UserRole.editor);
    });

    test('salik toMap round-trips approval fields', () {
      const salik = Salik(
        salikId: 'id-1',
        nameEnglish: 'Test',
        nameUrdu: 'ٹیسٹ',
        fatherNameEnglish: 'Father',
        fatherNameUrdu: 'والد',
        mobileNumber: '0300-1111111',
        whatsappNumber: '0300-1111111',
        cityId: 'c1',
        areaId: 'a1',
        genderId: 'Male',
        bazamId: '',
        khanqahId: '',
        salikCategoryId: '',
        dateOfBaith: '2024-01-01',
        referenceName: '',
        referenceMobile: '',
        isNafiAsbat: false,
        isSahibEMehfil: false,
        profilePicture: '',
        createdDate: '2024-01-01',
        modifiedDate: '2024-01-01',
        isActive: false,
        approvalStatus: ApprovalStatus.pending,
        addedByUid: 'editor-uid',
        addedByName: 'Male Editor',
      );

      final restored = Salik.fromMap(salik.toMap(), id: salik.salikId);
      expect(restored.approvalStatus, ApprovalStatus.pending);
      expect(restored.addedByUid, 'editor-uid');
      expect(restored.isActive, isFalse);
    });

    test('drift companion stores approval status', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const salik = Salik(
        salikId: 'pending-1',
        nameEnglish: 'Pending Salik',
        nameUrdu: '',
        fatherNameEnglish: 'Father',
        fatherNameUrdu: '',
        mobileNumber: '0300-2222222',
        whatsappNumber: '0300-2222222',
        cityId: 'c1',
        areaId: 'a1',
        genderId: 'Male',
        bazamId: '',
        khanqahId: '',
        salikCategoryId: '',
        dateOfBaith: '2024-01-01',
        referenceName: '',
        referenceMobile: '',
        isNafiAsbat: false,
        isSahibEMehfil: false,
        profilePicture: '',
        createdDate: '2024-01-01',
        modifiedDate: '2024-01-01',
        isActive: false,
        approvalStatus: ApprovalStatus.pending,
      );

      await db.upsertSalik(salikToCompanion(salik, syncStatus: pendingCreate));

      final row = await db.getSalikById('pending-1');
      expect(row, isNotNull);
      expect(row!.approvalStatus, 'pending');
      expect(row.toSalik().isPending, isTrue);

      final approvedOnly = await db.getAllSaliks(
        approvalStatus: ApprovalStatus.approved.toFirestore(),
      );
      expect(approvedOnly, isEmpty);
    });

    test('genderAdmin gender filter scopes to own gender', () {
      const femaleAdmin = UserSession(
        uid: 'uid-f',
        name: 'Female Admin',
        email: 'femaleadmin@salikeen.com',
        role: UserRole.genderAdmin,
        gender: 'Female',
      );
      expect(AccessControl.genderFilter(femaleAdmin), 'Female');
      expect(AccessControl.isGenderAdmin(femaleAdmin.role), isTrue);

      final saliks = [
        _sampleSalik(id: 'm1', genderId: 'Male'),
        _sampleSalik(id: 'f1', genderId: 'Female'),
      ];
      final scoped = scopeSaliksToSession(saliks, femaleAdmin);
      expect(scoped.map((s) => s.salikId), ['f1']);
    });

    test('mergeSalikOutbox uses synced local cache when offline', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const cached = Salik(
        salikId: 'cached-1',
        nameEnglish: 'Cached',
        nameUrdu: '',
        fatherNameEnglish: 'Father',
        fatherNameUrdu: '',
        mobileNumber: '0300-3333333',
        whatsappNumber: '0300-3333333',
        cityId: 'c1',
        areaId: 'a1',
        genderId: 'Female',
        bazamId: '',
        khanqahId: '',
        salikCategoryId: '',
        dateOfBaith: '2024-01-01',
        referenceName: '',
        referenceMobile: '',
        isNafiAsbat: false,
        isSahibEMehfil: false,
        profilePicture: '',
        createdDate: '2024-01-01',
        modifiedDate: '2024-01-01',
        isActive: true,
        approvalStatus: ApprovalStatus.approved,
      );

      await db.upsertSalik(salikToCompanion(cached, syncStatus: synced));

      final merged = mergeSalikOutbox(
        remote: const [],
        localRows: await db.getAllSaliks(genderFilter: 'Female'),
        includeLocal: (s) => s.isApproved,
        includeSyncedLocal: true,
      );

      expect(merged.single.salikId, 'cached-1');
    });

    test('mergeSalikOutbox prefers remote over synced cache when online', () {
      const remote = Salik(
        salikId: 's1',
        nameEnglish: 'Remote',
        nameUrdu: '',
        fatherNameEnglish: 'Father',
        fatherNameUrdu: '',
        mobileNumber: '03001111111',
        whatsappNumber: '03001111111',
        cityId: 'c1',
        areaId: 'a1',
        genderId: 'Female',
        bazamId: '',
        khanqahId: '',
        salikCategoryId: '',
        dateOfBaith: '2024-01-01',
        referenceName: '',
        referenceMobile: '',
        isNafiAsbat: false,
        isSahibEMehfil: false,
        profilePicture: '',
        createdDate: '2024-01-01',
        modifiedDate: '2024-01-01',
        isActive: true,
        approvalStatus: ApprovalStatus.approved,
      );

      final merged = mergeSalikOutbox(
        remote: [remote],
        localRows: const [],
        includeRemote: (s) => s.isApproved,
        includeLocal: (s) => s.isApproved,
        includeSyncedLocal: true,
      );

      expect(merged.single.nameEnglish, 'Remote');
    });
  });
}

Salik _sampleSalik({required String id, required String genderId}) {
  return Salik(
    salikId: id,
    nameEnglish: 'Name $id',
    nameUrdu: '',
    fatherNameEnglish: 'Father',
    fatherNameUrdu: '',
    mobileNumber: '0300$id',
    whatsappNumber: '0300$id',
    cityId: 'c1',
    areaId: 'a1',
    genderId: genderId,
    bazamId: '',
    khanqahId: '',
    salikCategoryId: '',
    dateOfBaith: '2024-01-01',
    referenceName: '',
    referenceMobile: '',
    isNafiAsbat: false,
    isSahibEMehfil: false,
    profilePicture: '',
    createdDate: '2024-01-01',
    modifiedDate: '2024-01-01',
    isActive: true,
    approvalStatus: ApprovalStatus.approved,
  );
}
