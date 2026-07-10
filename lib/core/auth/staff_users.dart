import '../../features/auth/domain/user_session.dart';
import '../config/app_config.dart';
import 'local_auth_store.dart';
import 'staff_user.dart';
import 'staff_users_dev.dart';
import 'staff_users_prod.dart';

export 'staff_user.dart';

List<StaffUser> get kStaffUsers =>
    AppConfig.isProd ? kStaffUsersProd : kStaffUsersDev;

String get kBootstrapAdminEmail =>
    AppConfig.isProd ? kBootstrapAdminEmailProd : kBootstrapAdminEmailDev;

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
