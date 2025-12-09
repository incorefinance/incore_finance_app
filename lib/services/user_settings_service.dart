import 'package:shared_preferences/shared_preferences.dart';

/// Model representing user currency settings with code, symbol, and locale
class UserCurrencySettings {
  final String currencyCode; // "EUR", "USD", etc.
  final String symbol; // "€", "\$"
  final String locale; // "pt_PT" for EUR, "en_US" for USD

  const UserCurrencySettings({
    required this.currencyCode,
    required this.symbol,
    required this.locale,
  });
}

/// Service for managing user settings and preferences
class UserSettingsService {
  static const String _currencyCodeKey = 'currency';

  /// Get current currency settings from SharedPreferences
  /// Returns EUR as default if no currency is set
  Future<UserCurrencySettings> getCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_currencyCodeKey) ?? 'EUR';

    return _getCurrencySettingsForCode(code);
  }

  /// Get currency settings for a specific currency code
  UserCurrencySettings _getCurrencySettingsForCode(String code) {
    switch (code) {
      case 'USD':
        return const UserCurrencySettings(
          currencyCode: 'USD',
          symbol: '\$',
          locale: 'en_US',
        );
      case 'BRL':
        return const UserCurrencySettings(
          currencyCode: 'BRL',
          symbol: 'R\$',
          locale: 'pt_BR',
        );
      case 'GBP':
        return const UserCurrencySettings(
          currencyCode: 'GBP',
          symbol: '£',
          locale: 'en_GB',
        );
      case 'EUR':
      default:
        return const UserCurrencySettings(
          currencyCode: 'EUR',
          symbol: '€',
          locale: 'pt_PT',
        );
    }
  }

  /// Save currency code to SharedPreferences
  Future<void> saveCurrencyCode(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, currencyCode);
  }

  /// Get currency settings synchronously (requires code to be passed)
  UserCurrencySettings getCurrencySettingsSync(String currencyCode) {
    return _getCurrencySettingsForCode(currencyCode);
  }
}
