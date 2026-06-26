import 'package:shared_preferences/shared_preferences.dart';

enum SalikContactAction {
  call,
  sms,
  whatsappMessage,
  whatsappCall,
}

class SalikContactPreference {
  SalikContactPreference._();

  static const _key = 'salik_preferred_contact_action';

  static Future<SalikContactAction> getPreferred() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    for (final action in SalikContactAction.values) {
      if (action.name == value) return action;
    }
    return SalikContactAction.call;
  }

  static Future<void> setPreferred(SalikContactAction action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, action.name);
  }
}
