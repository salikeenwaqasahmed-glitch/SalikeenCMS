import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salik_management_system/core/auth/local_auth_store.dart';
import 'package:salik_management_system/core/auth/local_user_seed.dart';
import 'package:salik_management_system/core/auth/seed_credentials.dart';
import 'package:salik_management_system/core/auth/staff_users.dart';
import 'package:salik_management_system/core/config/app_config.dart';
import 'package:salik_management_system/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('staff seed credentials', () {
    late AppDatabase db;
    late LocalAuthStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      store = LocalAuthStore(db);
      await LocalUserSeed.ensureUsers(store);
    });

    tearDown(() async {
      await db.close();
    });

    test('dev madmin password verifies when APP_ENV is dev', () async {
      expect(AppConfig.isDev, isTrue);
      expect(
        await store.verifyPassword('madmin@dev.cms.com', SeedCredentials.defaultPassword),
        isTrue,
      );
    });

    test('all dev roster emails exist locally after seed', () async {
      for (final staff in kStaffUsers) {
        final user = await store.getUserByEmail(staff.email);
        expect(user, isNotNull, reason: 'missing ${staff.email}');
        expect(user!.uid, 'local-${staff.email.toLowerCase()}');
      }
    });

    test('wrong password fails verify', () async {
      expect(
        await store.verifyPassword('madmin@dev.cms.com', 'wrong'),
        isFalse,
      );
    });
  });
}
