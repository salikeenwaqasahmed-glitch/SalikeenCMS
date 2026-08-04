import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salik_management_system/core/auth/local_auth_store.dart';
import 'package:salik_management_system/core/database/app_database.dart';
import 'package:salik_management_system/features/auth/domain/user_role.dart';
import 'package:salik_management_system/features/auth/domain/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('local auth store (no roster seed)', () {
    late AppDatabase db;
    late LocalAuthStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      store = LocalAuthStore(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('unknown email has no local user', () async {
      expect(await store.getUserByEmail('nobody@dev.cms.com'), isNull);
      expect(
        await store.verifyPassword('nobody@dev.cms.com', 'any'),
        isFalse,
      );
    });

    test('saved user with password verifies offline', () async {
      await store.saveUser(
        const UserSession(
          uid: 'uid-1',
          name: 'Admin',
          email: 'madmin@dev.cms.com',
          role: UserRole.admin,
          gender: 'Male',
        ),
        password: 'Secret123!',
      );
      expect(
        await store.verifyPassword('madmin@dev.cms.com', 'Secret123!'),
        isTrue,
      );
      expect(
        await store.verifyPassword('madmin@dev.cms.com', 'wrong'),
        isFalse,
      );
    });

    test('NoLocalUserOfflineException is distinct type', () {
      expect(const NoLocalUserOfflineException(), isA<Exception>());
    });
  });
}
