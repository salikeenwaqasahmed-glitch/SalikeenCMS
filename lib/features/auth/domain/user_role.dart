enum UserRole {
  admin,
  genderAdmin,
  editor,
  crudUser;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Global Admin';
      case UserRole.genderAdmin:
        return 'Gender Admin';
      case UserRole.editor:
        return 'Editor';
      case UserRole.crudUser:
        return 'CRUD User';
    }
  }

  String l10nKey() {
    switch (this) {
      case UserRole.admin:
        return 'role_admin';
      case UserRole.genderAdmin:
        return 'role_gender_admin';
      case UserRole.editor:
        return 'role_editor';
      case UserRole.crudUser:
        return 'role_crud_user';
    }
  }

  static UserRole fromString(String value) {
    final normalized =
        value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    switch (normalized) {
      case 'admin':
      case 'globaladmin':
        return UserRole.admin;
      case 'genderadmin':
        return UserRole.genderAdmin;
      case 'editor':
        return UserRole.editor;
      case 'cruduser':
        return UserRole.editor;
      default:
        return UserRole.editor;
    }
  }

  String toFirestore() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.genderAdmin:
        return 'genderAdmin';
      case UserRole.editor:
      case UserRole.crudUser:
        return 'editor';
    }
  }
}
