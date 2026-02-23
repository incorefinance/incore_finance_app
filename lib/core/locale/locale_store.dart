import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles locale persistence using SharedPreferences.
class LocaleStore {
  static const String _key = 'selected_locale';

  /// Saves the locale code to SharedPreferences.
  /// Accepts "en" or "pt_PT".
  static Future<void> saveLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  /// Loads the saved locale code from SharedPreferences.
  /// Returns null if no locale has been saved.
  static Future<String?> loadLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Parses a locale code string into a Locale object.
  /// - "en" -> Locale('en')
  /// - "pt_PT" -> Locale('pt', 'PT')
  /// Returns null if code is null or unrecognized.
  static Locale? parseToLocale(String? code) {
    if (code == null) return null;

    switch (code) {
      case 'en':
        return const Locale('en');
      case 'pt_PT':
        return const Locale('pt', 'PT');
      default:
        return null;
    }
  }

  /// Checks if a locale has been previously saved.
  static Future<bool> hasLocale() async {
    final code = await loadLocaleCode();
    return code != null;
  }
}
