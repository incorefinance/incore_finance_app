import 'package:intl/intl.dart';

/// Centralized number formatting utility for Incore Finance
///
/// Rules:
/// - Currency formatting uses intl's currency formatter (locale + currencyCode + symbol)
/// - Decimal formatting is used only when you explicitly want "no symbol"
/// - Parsing keeps your existing tolerant behavior for user input
class IncoreNumberFormatter {
  // ----------------------------
  // Formatters
  // ----------------------------

  static NumberFormat _decimal2(String locale) {
    final f = NumberFormat.decimalPattern(locale);
    f.minimumFractionDigits = 2;
    f.maximumFractionDigits = 2;
    return f;
  }

  static NumberFormat _currency({
    required String locale,
    required String currencyCode,
    required String symbol,
  }) {
    // This is the correct way: intl will handle spacing and separators per locale.
    return NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: symbol,
    );
  }

  // ----------------------------
  // Public formatting API
  // ----------------------------

  /// Formats a numeric amount with 2 decimals (no currency symbol).
  static String formatAmount(
    num value, {
    required String locale,
  }) {
    return _decimal2(locale).format(value);
  }

  /// Formats amount as currency using locale + currencyCode + symbol.
  static String formatMoney(
    num value, {
    required String locale,
    required String currencyCode,
    required String symbol,
  }) {
    return _currency(
      locale: locale,
      currencyCode: currencyCode,
      symbol: symbol,
    ).format(value);
  }

  /// Formats a transaction amount with a sign.
  /// - Positive: "+ €1,234.56" (optional)
  /// - Negative: "- €1,234.56"
  ///
  /// If you want "expenses show minus, income shows no plus", set `showPlus=false`.
  static String formatTransactionMoney(
    num value, {
    required String locale,
    required String currencyCode,
    required String symbol,
    bool showPlus = false,
  }) {
    final absFormatted = formatMoney(
      value.abs(),
      locale: locale,
      currencyCode: currencyCode,
      symbol: symbol,
    );

    if (value < 0) return '- $absFormatted';
    if (value > 0 && showPlus) return '+ $absFormatted';
    return absFormatted;
  }

  // ----------------------------
  // Parsing (kept from your version)
  // ----------------------------

  /// Parses a user-typed amount string into a double, respecting the given locale.
  ///
  /// Handles both European format (1.234,56) and US format (1,234.56).
  /// Returns null if the input cannot be parsed into a valid amount.
  static double? parseAmount(
    String input, {
    required String locale,
  }) {
    if (input.trim().isEmpty) return null;

    // Remove any currency symbols and whitespace
    final cleaned = input.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (cleaned.isEmpty) return null;

    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');

    String normalized = cleaned;

    final usesCommaAsDecimal = locale.startsWith('pt') ||
        locale.startsWith('de') ||
        locale.startsWith('fr') ||
        locale.startsWith('it') ||
        locale.startsWith('es');

    if (lastComma != -1 && lastDot != -1) {
      if (usesCommaAsDecimal) {
        if (lastComma > lastDot) {
          normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          normalized = cleaned.replaceAll(',', '');
        }
      } else {
        if (lastDot > lastComma) {
          normalized = cleaned.replaceAll(',', '');
        } else {
          normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
        }
      }
    } else if (lastComma != -1) {
      final charsAfterComma = cleaned.length - lastComma - 1;

      if (usesCommaAsDecimal && charsAfterComma <= 2) {
        normalized = cleaned.replaceAll(',', '.');
      } else {
        normalized = cleaned.replaceAll(',', '');
      }
    } else if (lastDot != -1) {
      final charsAfterDot = cleaned.length - lastDot - 1;

      if (!usesCommaAsDecimal || charsAfterDot <= 2) {
        normalized = cleaned;
      } else {
        normalized = cleaned.replaceAll('.', '');
      }
    }

    return double.tryParse(normalized);
  }
}
