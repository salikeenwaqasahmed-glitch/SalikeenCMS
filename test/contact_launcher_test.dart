import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/core/utils/contact_launcher.dart';

void main() {
  group('ContactLauncher WhatsApp URIs', () {
    test('builds a native WhatsApp call URI for Pakistani numbers', () {
      final uri = ContactLauncher.whatsappCallUri('03001234567');

      expect(uri.scheme, 'whatsapp');
      expect(uri.host, 'call');
      expect(uri.queryParameters['phone'], '+923001234567');
    });

    test('builds a WhatsApp web URI for existing international numbers', () {
      final uri = ContactLauncher.whatsappMessageUri('+14155552671');

      expect(uri.toString(), 'https://wa.me/%2B14155552671');
    });
  });
}
