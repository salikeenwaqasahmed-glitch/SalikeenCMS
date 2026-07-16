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

  static String _normalizeForWhatsApp(String phone) {
    final normalized = _normalizeForLaunch(phone);
    if (normalized.isEmpty) return '';
    return normalized.startsWith('+') ? normalized : '+$normalized';
  }

  static Uri whatsappMessageUri(String phone) {
    final normalized = _normalizeForWhatsApp(phone);
    if (normalized.isEmpty) return Uri.parse('https://wa.me/');
    return Uri.parse('https://wa.me/${Uri.encodeComponent(normalized)}');
  }

  static Uri whatsappCallUri(String phone) {
    final normalized = _normalizeForWhatsApp(phone);
    if (normalized.isEmpty) {
      return Uri.parse('whatsapp://call');
    }

    return Uri(
      scheme: 'whatsapp',
      host: 'call',
      queryParameters: {'phone': normalized},
    );
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

  static Future<void> whatsappMessage(String phone) async {
    final uri = whatsappMessageUri(phone);
    if (uri.path == '/'){ 
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> whatsappCall(String phone) async {
    final callUri = whatsappCallUri(phone);
    if (callUri.queryParameters['phone']?.isEmpty ?? true) return;

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
      return;
    }

    await launchUrl(whatsappMessageUri(phone), mode: LaunchMode.externalApplication);
  }

  static bool sameNumber(String a, String b) =>
      SalikRepository.normalizePhone(a) == SalikRepository.normalizePhone(b);
}
