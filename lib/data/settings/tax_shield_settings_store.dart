import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the user's tax shield percentage.
///
/// Stores a [0.0, 1.0] double via SharedPreferences.
/// [defaultPercent] is the single source of truth for the fallback value.
class TaxShieldSettingsStore {
  static const double defaultPercent = 0.25;
  static const String _key = 'tax_shield_percent';

  /// Returns the stored tax shield percent, or [defaultPercent] if unset.
  Future<double> getTaxShieldPercent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? defaultPercent;
  }

  /// Persists [percent], clamped to [0.0, 1.0].
  Future<void> setTaxShieldPercent(double percent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, percent.clamp(0.0, 1.0));
  }
}
