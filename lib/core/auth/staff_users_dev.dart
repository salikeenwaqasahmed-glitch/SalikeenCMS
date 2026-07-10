import '../../features/auth/domain/user_role.dart';
import 'staff_user.dart';

const kStaffUsersDev = <StaffUser>[
  StaffUser(
    email: 'meditor@dev.cms.com',
    name: 'Editor M',
    role: UserRole.editor,
    gender: 'Male',
  ),
  StaffUser(
    email: 'feditor@dev.cms.com',
    name: 'Editor F',
    role: UserRole.editor,
    gender: 'Female',
  ),
  StaffUser(
    email: 'mapprove@dev.cms.com',
    name: 'Approval M',
    role: UserRole.approval,
    gender: 'Male',
  ),
  StaffUser(
    email: 'fapprove@dev.cms.com',
    name: 'Approval F',
    role: UserRole.approval,
    gender: 'Female',
  ),
  StaffUser(
    email: 'madmin@dev.cms.com',
    name: 'Admin M',
    role: UserRole.admin,
    gender: 'Male',
  ),
  StaffUser(
    email: 'fadmin@dev.cms.com',
    name: 'Admin F',
    role: UserRole.admin,
    gender: 'Female',
  ),
];

const kBootstrapAdminEmailDev = 'madmin@dev.cms.com';
