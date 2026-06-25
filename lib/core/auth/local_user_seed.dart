import '../../features/auth/domain/user_role.dart';
import '../../features/auth/domain/user_session.dart';
import 'local_auth_store.dart';
import 'seed_credentials.dart';

/// Pre-seeds known app users into local Drift so offline login works
/// without a prior online session on this device.
class LocalUserSeed {
  LocalUserSeed._();

  static const defaultPassword = SeedCredentials.defaultPassword;

  static const _users = [
    (
      email: 'admin@salikeen.com',
      name: 'Global Admin',
      role: UserRole.admin,
      gender: 'Male',
    ),
    (
      email: 'maleadmin@salikeen.com',
      name: 'Male Gender Admin',
      role: UserRole.genderAdmin,
      gender: 'Male',
    ),
    (
      email: 'femaleadmin@salikeen.com',
      name: 'Female Gender Admin',
      role: UserRole.genderAdmin,
      gender: 'Female',
    ),
    (
      email: 'maleeditor@salikeen.com',
      name: 'Male Editor',
      role: UserRole.editor,
      gender: 'Male',
    ),
    (
      email: 'femaleeditor@salikeen.com',
      name: 'Female Editor',
      role: UserRole.editor,
      gender: 'Female',
    ),
  ];

  static Future<void> ensureUsers(LocalAuthStore store) async {
    for (final user in _users) {
      final email = LocalAuthStore.normalizeEmail(user.email);
      await store.ensureLocalUser(
        session: UserSession(
          uid: 'local-$email',
          name: user.name,
          email: email,
          role: user.role,
          gender: user.gender,
        ),
        password: defaultPassword,
        refreshPassword: true,
      );
    }
  }

  /// Known demo account profile (email → role/gender) for Firestore repair.
  static UserSession? profileForEmail(String email) {
    final normalized = LocalAuthStore.normalizeEmail(email);
    for (final user in _users) {
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
}
