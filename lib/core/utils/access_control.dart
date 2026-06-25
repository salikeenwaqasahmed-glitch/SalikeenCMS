import '../../features/auth/domain/user_role.dart';
import '../../features/auth/domain/user_session.dart';

class AccessControl {
  static bool canCreate(UserRole role) =>
      role == UserRole.admin ||
      role == UserRole.genderAdmin ||
      role == UserRole.editor;

  static bool canUpdate(UserRole role) =>
      role == UserRole.admin || role == UserRole.genderAdmin;

  static bool canDelete(UserRole role) =>
      role == UserRole.admin || role == UserRole.genderAdmin;

  static bool canApprove(UserRole role) =>
      role == UserRole.admin || role == UserRole.genderAdmin;

  static bool canViewPending(UserRole role) =>
      role == UserRole.admin ||
      role == UserRole.genderAdmin ||
      role == UserRole.editor;

  static bool isEditor(UserRole role) => role == UserRole.editor;

  static bool isGenderAdmin(UserRole role) => role == UserRole.genderAdmin;

  static bool canViewAllGenders(UserRole role) => role == UserRole.admin;

  static String? genderFilter(UserSession? session) {
    if (session == null) return null;
    if (canViewAllGenders(session.role)) return null;
    return session.gender;
  }

  static bool canSetGender(UserSession session) =>
      session.role == UserRole.admin;

  static String effectiveGender(UserSession session, String selectedGender) {
    if (session.role == UserRole.admin) {
      return UserSession.normalizeGender(selectedGender);
    }
    return UserSession.normalizeGender(session.gender);
  }
}
