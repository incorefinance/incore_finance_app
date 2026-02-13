import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the user's safety buffer percentage.
///
/// Stores a [0.0, 1.0] double via SharedPreferences.
/// [defaultPercent] is the single source of truth for the fallback value.
class SafetyBufferSettingsStore {
  static const double defaultPercent = 0.10;
  static const String _key = 'safety_buffer_percent';

  /// Returns the stored safety buffer percent, or [defaultPercent] if unset.
  Future<double> getSafetyBufferPercent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? defaultPercent;
  }

  /// Persists [percent], clamped to [0.0, 1.0].
  Future<void> setSafetyBufferPercent(double percent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, percent.clamp(0.0, 1.0));
  }
}
