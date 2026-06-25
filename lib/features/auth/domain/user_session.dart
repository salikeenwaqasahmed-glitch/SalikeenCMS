import 'user_role.dart';

class UserSession {
  const UserSession({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.gender,
    this.avatar,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String gender;
  final String? avatar;

  factory UserSession.fromMap(String uid, Map<String, dynamic> map) {
    return UserSession(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'editor'),
      gender: UserSession.normalizeGender(map['gender'] as String?),
      avatar: map['avatar'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.toFirestore(),
      'gender': gender,
      'avatar': avatar,
    };
  }

  /// Firestore + salik rules expect `Male` or `Female`.
  static String normalizeGender(String? value) {
    final lower = (value ?? 'Male').trim().toLowerCase();
    if (lower == 'female') return 'Female';
    return 'Male';
  }
}
