import '../../features/auth/domain/user_role.dart';

/// Canonical CMS staff roster entry.
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
