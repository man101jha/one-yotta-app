import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Set user registered
  static Future<void> setUserRegistered(bool value) async {
    await _prefs?.setBool('isRegistered', value);
  }

  /// Check if user is registered
  static bool isUserRegistered() {
    return _prefs?.getBool('isRegistered') ?? false;
  }
}
