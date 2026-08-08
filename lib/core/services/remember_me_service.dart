import 'package:shared_preferences/shared_preferences.dart';

enum PortalType {
  customer,
  owner,
}

class RememberMeService {
  static String _getRememberKey(PortalType portal) {
    return portal == PortalType.owner ? 'remember_me_owner' : 'remember_me_customer';
  }

  static String _getEmailKey(PortalType portal) {
    return portal == PortalType.owner ? 'remembered_email_owner' : 'remembered_email_customer';
  }

  /// Saves or clears the remembered email based on portal type
  static Future<void> saveRememberedUser({
    required bool rememberMe,
    required String email,
    PortalType portal = PortalType.customer,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberKey = _getRememberKey(portal);
      final emailKey = _getEmailKey(portal);

      if (rememberMe && email.trim().isNotEmpty) {
        await prefs.setBool(rememberKey, true);
        await prefs.setString(emailKey, email.trim());
      } else {
        await prefs.setBool(rememberKey, false);
        await prefs.remove(emailKey);
      }
    } catch (_) {}
  }

  /// Retrieves the saved Remember Me preference and email for a specific portal
  static Future<Map<String, dynamic>> getRememberedUser({
    PortalType portal = PortalType.customer,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberKey = _getRememberKey(portal);
      final emailKey = _getEmailKey(portal);

      final rememberMe = prefs.getBool(rememberKey) ?? false;
      final email = prefs.getString(emailKey) ?? '';
      return {
        'rememberMe': rememberMe && email.isNotEmpty,
        'email': rememberMe ? email : '',
      };
    } catch (_) {
      return {'rememberMe': false, 'email': ''};
    }
  }
}
