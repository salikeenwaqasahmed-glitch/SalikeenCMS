import 'package:url_launcher/url_launcher.dart';

import '../../features/saliks/data/salik_repository.dart';

/// Opens phone / SMS / WhatsApp URIs for a salik contact number.
class ContactLauncher {
  ContactLauncher._();

  static String digitsOnly(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  static Future<void> call(String phone) {
    return launchUrl(Uri.parse('tel:$phone'));
  }

  static Future<void> sms(String phone) {
    final digits = digitsOnly(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(Uri.parse('sms:$digits'));
  }

  static Future<void> whatsappMessage(String phone) {
    final digits = digitsOnly(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> whatsappCall(String phone) {
    final digits = digitsOnly(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(
      Uri.parse('whatsapp://call?phone=$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  static bool sameNumber(String a, String b) =>
      SalikRepository.normalizePhone(a) == SalikRepository.normalizePhone(b);
}
