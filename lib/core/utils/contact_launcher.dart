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

  static Uri whatsappMessageUri(String phone, {String? text}) {
    final normalized = _normalizeForWhatsApp(phone);
    if (normalized.isEmpty) return Uri.parse('https://wa.me/');
    final digits = normalized.replaceAll('+', '');
    final params = <String, String>{};
    final body = text?.trim() ?? '';
    if (body.isNotEmpty) params['text'] = body;
    return Uri.https('wa.me', '/$digits', params.isEmpty ? null : params);
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

  static Future<void> sms(String phone, {String? body}) {
    final digits = _normalizeForLaunch(phone);
    if (digits.isEmpty) return Future.value();
    final trimmed = body?.trim() ?? '';
    final uri = trimmed.isEmpty
        ? Uri.parse('sms:+$digits')
        : Uri(
            scheme: 'sms',
            path: '+$digits',
            queryParameters: {'body': trimmed},
          );
    return launchUrl(uri);
  }

  static Future<void> whatsappMessage(String phone, {String? text}) async {
    final uri = whatsappMessageUri(phone, text: text);
    if (uri.path == '/' || uri.path.isEmpty) {
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

  /// WhatsApp number if set, otherwise mobile.
  static String whatsappPhoneForSalik({
    required String mobileNumber,
    required String whatsappNumber,
  }) {
    final wa = whatsappNumber.trim();
    if (wa.isNotEmpty) return wa;
    return mobileNumber;
  }

  static bool sameNumber(String a, String b) =>
      SalikRepository.normalizePhone(a) == SalikRepository.normalizePhone(b);
}
