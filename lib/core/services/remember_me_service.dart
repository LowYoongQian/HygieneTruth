import 'package:shared_preferences/shared_preferences.dart';

class RememberMeService {
  static const String _keyRememberMe = 'remember_me_enabled';
  static const String _keyRememberedEmail = 'remembered_user_email';

  /// Saves or clears the remembered email based on the Remember Me toggle state
  static Future<void> saveRememberedUser({
    required bool rememberMe,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe && email.trim().isNotEmpty) {
        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keyRememberedEmail, email.trim());
      } else {
        await prefs.setBool(_keyRememberMe, false);
        await prefs.remove(_keyRememberedEmail);
      }
    } catch (_) {}
  }

  /// Retrieves the saved Remember Me preference and remembered email from device local storage
  static Future<Map<String, dynamic>> getRememberedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      final email = prefs.getString(_keyRememberedEmail) ?? '';
      return {
        'rememberMe': rememberMe && email.isNotEmpty,
        'email': rememberMe ? email : '',
      };
    } catch (_) {
      return {'rememberMe': false, 'email': ''};
    }
  }
}
