import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences], mirroring the storageGet/storageSet
/// helpers in the web app (JSON-encoded values under a string key, with a
/// fallback when the key is missing or unreadable — never throws).
///
/// Must be initialized once with [Storage.init] before use (done in main()
/// before runApp, so every screen can use it synchronously afterwards).
class Storage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static T get<T>(String key, T fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    try {
      return jsonDecode(raw) as T;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> set(String key, Object? value) async {
    try {
      await _prefs.setString(key, jsonEncode(value));
    } catch (_) {
      // Best-effort, same as the web app's try/catch around localStorage.
    }
  }

  static Future<void> remove(String key) => _prefs.remove(key);
}
