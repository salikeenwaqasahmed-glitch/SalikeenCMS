import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/features/saliks/data/duplicate_salik_logic.dart';
import 'package:salik_management_system/features/saliks/domain/entities/approval_status.dart';
import 'package:salik_management_system/features/saliks/domain/entities/salik.dart';

void main() {
  group('findSalikDuplicateGroups', () {
    test('marks records as duplicates only when name/father-name and mobile both match', () { 
      final saliks = [
        const Salik(
          salikId: '1',
          name: 'Ali',
          fatherName: 'Ahmed',
          mobileNumber: '03001234567',
          whatsappNumber: '',
          areaId: '',
          genderId: 'Male',
          bazamId: '',
          khanqahId: '',
          salikCategoryId: '',
          dateOfBaith: '',
          referenceName: '',
          referenceMobile: '',
          isNafiAsbat: false,
          isSahibEMehfil: false,
          profilePicture: '',
          createdDate: '2024-01-01',
          modifiedDate: '2024-01-01',
          isActive: true,
          approvalStatus: ApprovalStatus.approved,
        ),
        const Salik(
          salikId: '2',
          name: 'Ali',
          fatherName: 'Ahmed',
          mobileNumber: '03001234568',
          whatsappNumber: '',
          areaId: '',
          genderId: 'Male',
          bazamId: '',
          khanqahId: '',
          salikCategoryId: '',
          dateOfBaith: '',
          referenceName: '',
          referenceMobile: '',
          isNafiAsbat: false,
          isSahibEMehfil: false,
          profilePicture: '',
          createdDate: '2024-01-02',
          modifiedDate: '2024-01-02',
          isActive: true,
          approvalStatus: ApprovalStatus.approved,
        ),
        const Salik(
          salikId: '3',
          name: 'Ali',
          fatherName: 'Ahmed',
          mobileNumber: '03001234567',
          whatsappNumber: '',
          areaId: '',
          genderId: 'Male',
          bazamId: '',
          khanqahId: '',
          salikCategoryId: '',
          dateOfBaith: '',
          referenceName: '',
          referenceMobile: '',
          isNafiAsbat: false,
          isSahibEMehfil: false,
          profilePicture: '',
          createdDate: '2024-01-03',
          modifiedDate: '2024-01-03',
          isActive: true,
          approvalStatus: ApprovalStatus.approved,
        ),
      ];

      final groups = findSalikDuplicateGroups(saliks);

      expect(groups, hasLength(1));
      expect(groups.single.saliks.map((s) => s.salikId), ['1', '3']);
    });
  });
}
