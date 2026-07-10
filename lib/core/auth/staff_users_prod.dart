import '../../features/auth/domain/user_role.dart';
import 'staff_user.dart';

const kStaffUsersProd = <StaffUser>[
  StaffUser(
    email: 'naveed@cms.com',
    name: 'Naveed',
    role: UserRole.editor,
    gender: 'Male',
  ),
  StaffUser(
    email: 'ayaz@cms.com',
    name: 'Ayaz',
    role: UserRole.editor,
    gender: 'Male',
  ),
  StaffUser(
    email: 'mawaz@cms.com',
    name: 'Mawaz',
    role: UserRole.editor,
    gender: 'Male',
  ),
  StaffUser(
    email: 'imran@cms.com',
    name: 'Imran',
    role: UserRole.editor,
    gender: 'Male',
  ),
  StaffUser(
    email: 'adil@cms.com',
    name: 'Adil',
    role: UserRole.approval,
    gender: 'Male',
  ),
  StaffUser(
    email: 'waheed@cms.com',
    name: 'Waheed',
    role: UserRole.approval,
    gender: 'Male',
  ),
  StaffUser(
    email: 'usman@cms.com',
    name: 'Usman',
    role: UserRole.approval,
    gender: 'Male',
  ),
  StaffUser(
    email: 'sarkar@cms.com',
    name: 'Sarkar',
    role: UserRole.admin,
    gender: 'Male',
  ),
  StaffUser(
    email: 'waqas@cms.com',
    name: 'Waqas',
    role: UserRole.admin,
    gender: 'Male',
  ),
];

const kBootstrapAdminEmailProd = 'sarkar@cms.com';
