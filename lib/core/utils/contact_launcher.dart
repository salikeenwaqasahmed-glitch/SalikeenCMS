import 'package:url_launcher/url_launcher.dart';

import '../../features/saliks/data/salik_repository.dart';
import 'phone_number_utils.dart';

/// Opens phone / SMS / WhatsApp URIs for a salik contact number.
class ContactLauncher {
  ContactLauncher._();

  static String digitsOnly(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String _normalizeForLaunch(String phone) {
    final dialable = PhoneNumberUtils.toDialableDigits(phone);
    return dialable.isNotEmpty ? dialable : digitsOnly(phone);
  }

  static Future<void> call(String phone) {
    final digits = _normalizeForLaunch(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(Uri.parse('tel:+$digits'));
  }

  static Future<void> sms(String phone) {
    final digits = _normalizeForLaunch(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(Uri.parse('sms:+$digits'));
  }

  static Future<void> whatsappMessage(String phone) {
    final digits = _normalizeForLaunch(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> whatsappCall(String phone) {
    final digits = _normalizeForLaunch(phone);
    if (digits.isEmpty) return Future.value();
    return launchUrl(
      Uri.parse('whatsapp://call?phone=$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  static bool sameNumber(String a, String b) =>
      SalikRepository.normalizePhone(a) == SalikRepository.normalizePhone(b);
}
