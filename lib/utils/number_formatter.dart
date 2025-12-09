import 'package:intl/intl.dart';

/// Centralized number formatting utility for Incore Finance
class IncoreNumberFormatter {
  /// Returns a NumberFormat instance for the given locale
  static NumberFormat amountFormatForLocale(String locale) {
    return NumberFormat('#,##0.00', locale);
  }

  /// Formats a numeric amount according to the given locale
  static String formatAmount(
    num value, {
    required String locale,
  }) {
    final format = amountFormatForLocale(locale);
    return format.format(value);
  }

  /// Formats amount with currency symbol
  static String formatAmountWithCurrency(
    num value, {
    required String locale,
    required String symbol,
  }) {
    final format = amountFormatForLocale(locale);
    return '$symbol ${format.format(value)}';
  }

  /// Formats amount with currency symbol and sign for transactions
  static String formatTransactionAmount(
    num value, {
    required String locale,
    required String symbol,
  }) {
    final sign = value >= 0 ? '+' : '';
    final format = amountFormatForLocale(locale);
    return '$sign $symbol ${format.format(value.abs())}';
  }

  /// Parses a user-typed amount string into a double, respecting the given locale.
  ///
  /// Handles both European format (€1.234,56) and US format ($1,234.56).
  /// Returns null if the input cannot be parsed into a valid amount.
  ///
  /// Examples:
  /// - parseAmount("1.234,56", locale: "pt_PT") -> 1234.56
  /// - parseAmount("1,234.56", locale: "en_US") -> 1234.56
  /// - parseAmount("1234", locale: "pt_PT") -> 1234.0
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

    // Determine the decimal separator based on locale
    final usesCommaAsDecimal = locale.startsWith('pt') ||
        locale.startsWith('de') ||
        locale.startsWith('fr') ||
        locale.startsWith('it') ||
        locale.startsWith('es');

    if (lastComma != -1 && lastDot != -1) {
      // Both separators present - determine which is decimal
      if (usesCommaAsDecimal) {
        // European format: dot is thousands, comma is decimal
        // Example: 1.234,56 -> 1234.56
        if (lastComma > lastDot) {
          normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Unusual case: comma before dot, treat dot as decimal
          normalized = cleaned.replaceAll(',', '');
        }
      } else {
        // US format: comma is thousands, dot is decimal
        // Example: 1,234.56 -> 1234.56
        if (lastDot > lastComma) {
          normalized = cleaned.replaceAll(',', '');
        } else {
          // Unusual case: dot before comma, treat comma as decimal
          normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
        }
      }
    } else if (lastComma != -1) {
      // Only comma present
      final charsAfterComma = cleaned.length - lastComma - 1;

      if (usesCommaAsDecimal && charsAfterComma <= 2) {
        // Likely decimal separator: 123,45 -> 123.45
        normalized = cleaned.replaceAll(',', '.');
      } else {
        // Likely thousands separator: 1,234 -> 1234
        normalized = cleaned.replaceAll(',', '');
      }
    } else if (lastDot != -1) {
      // Only dot present
      final charsAfterDot = cleaned.length - lastDot - 1;

      if (!usesCommaAsDecimal || charsAfterDot <= 2) {
        // Keep dot as decimal separator
        normalized = cleaned;
      } else {
        // Treat dot as thousands separator: 1.234 -> 1234
        normalized = cleaned.replaceAll('.', '');
      }
    }

    return double.tryParse(normalized);
  }
}
