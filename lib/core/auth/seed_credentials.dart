import '../config/app_config.dart';
import 'staff_users.dart';

/// Shared seed account credentials for local login and Firebase re-auth.
class SeedCredentials {
  SeedCredentials._();

  static String get defaultPassword =>
      AppConfig.isProd ? 'cms@1234' : '12345678';

  static List<String> get seedEmails => kStaffEmails;
}
