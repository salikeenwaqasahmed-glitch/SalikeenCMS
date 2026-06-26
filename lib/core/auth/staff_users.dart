import '../../features/auth/domain/user_role.dart';
import '../../features/auth/domain/user_session.dart';
import 'local_auth_store.dart';

/// Canonical CMS staff roster — offline seed, Firebase provision, profile repair.
class StaffUser {
  const StaffUser({
    required this.email,
    required this.name,
    required this.role,
    required this.gender,
  });

  final String email;
  final String name;
  final UserRole role;
  final String gender;
}

const kStaffUsers = <StaffUser>[
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

/// Bootstrap admin used when provisioning other Firebase Auth accounts.
const kBootstrapAdminEmail = 'sarkar@cms.com';

String nameFromEmail(String email) {
  final local = LocalAuthStore.normalizeEmail(email).split('@').first;
  if (local.isEmpty) return email;
  return local[0].toUpperCase() + local.substring(1);
}

UserSession? staffProfileForEmail(String email) {
  final normalized = LocalAuthStore.normalizeEmail(email);
  for (final user in kStaffUsers) {
    if (LocalAuthStore.normalizeEmail(user.email) != normalized) continue;
    return UserSession(
      uid: '',
      name: user.name,
      email: normalized,
      role: user.role,
      gender: user.gender,
    );
  }
  return null;
}

List<String> get kStaffEmails =>
    kStaffUsers.map((u) => LocalAuthStore.normalizeEmail(u.email)).toList();
