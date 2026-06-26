import '../../features/auth/domain/user_session.dart';
import 'local_auth_store.dart';
import 'seed_credentials.dart';
import 'staff_users.dart';

/// Pre-seeds known CMS staff into local Drift so offline login works
/// without a prior online session on this device.
class LocalUserSeed {
  LocalUserSeed._();

  static const defaultPassword = SeedCredentials.defaultPassword;

  static Future<void> ensureUsers(LocalAuthStore store) async {
    for (final user in kStaffUsers) {
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

  /// Known staff profile (email → role/gender) for Firestore repair.
  static UserSession? profileForEmail(String email) => staffProfileForEmail(email);
}
