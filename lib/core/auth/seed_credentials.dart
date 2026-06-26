import 'staff_users.dart';

/// Shared seed account credentials for local login and Firebase re-auth.
class SeedCredentials {
  SeedCredentials._();

  static const defaultPassword = 'cms@1234';

  static List<String> get seedEmails => kStaffEmails;
}