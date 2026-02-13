// lib/models/protection_snapshot.dart
//
// Model for unified protection snapshot returned by get_protection_snapshot RPC.
// Contains all financial protection metrics in a single object.

/// Confidence level for expense averaging based on data availability.
enum ConfidenceLevel {
  low,
  medium,
  high;

  String get dbValue {
    switch (this) {
      case ConfidenceLevel.low:
        return 'low';
      case ConfidenceLevel.medium:
        return 'medium';
      case ConfidenceLevel.high:
        return 'high';
    }
  }

  static ConfidenceLevel fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return ConfidenceLevel.low;
      case 'medium':
        return ConfidenceLevel.medium;
      case 'high':
        return ConfidenceLevel.high;
      default:
        return ConfidenceLevel.low; // Default to low for safety
    }
  }
}

/// Unified snapshot of protection metrics.
///
/// Core formula: safe_to_spend = balance - tax_protected - safety_protected
class ProtectionSnapshot {
  /// Amount protected for taxes (sum of credits - debits).
  final double taxProtected;

  /// Amount protected for safety buffer (sum of credits - debits).
  final double safetyProtected;

  /// Current balance: starting_balance + income - expenses.
  final double balance;

  /// Amount available after protections: balance - tax - safety.
  final double safeToSpend;

  /// Average monthly expenses based on full months of data.
  final double avgMonthlyExpenses;

  /// Number of full months used for expense averaging (0-6).
  final int monthsUsed;

  /// Confidence in expense average: low (<3 months), medium (3-5), high (6).
  final ConfidenceLevel confidence;

  const ProtectionSnapshot({
    required this.taxProtected,
    required this.safetyProtected,
    required this.balance,
    required this.safeToSpend,
    required this.avgMonthlyExpenses,
    required this.monthsUsed,
    required this.confidence,
  });

  /// Parse from Supabase RPC response map.
  /// Handles NUMERIC -> double conversion robustly.
  factory ProtectionSnapshot.fromMap(Map<String, dynamic> map) {
    return ProtectionSnapshot(
      taxProtected: _parseDouble(map['tax_protected']),
      safetyProtected: _parseDouble(map['safety_protected']),
      balance: _parseDouble(map['balance']),
      safeToSpend: _parseDouble(map['safe_to_spend']),
      avgMonthlyExpenses: _parseDouble(map['avg_monthly_expenses']),
      monthsUsed: _parseInt(map['months_used']),
      confidence: ConfidenceLevel.fromDbValue(
        map['confidence']?.toString() ?? 'low',
      ),
    );
  }

  /// Parse numeric value to double (handles int, num, String, null).
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parse numeric value to int (handles int, num, String, null).
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Returns estimated runway in days based on avg monthly expenses.
  /// Returns null if no expense data available.
  double? get runwayDays {
    if (avgMonthlyExpenses <= 0) return null;
    final dailyExpense = avgMonthlyExpenses / 30.0;
    if (dailyExpense <= 0) return null;
    return safeToSpend / dailyExpense;
  }

  @override
  String toString() {
    return 'ProtectionSnapshot('
        'balance: $balance, '
        'taxProtected: $taxProtected, '
        'safetyProtected: $safetyProtected, '
        'safeToSpend: $safeToSpend, '
        'avgMonthlyExpenses: $avgMonthlyExpenses, '
        'monthsUsed: $monthsUsed, '
        'confidence: ${confidence.dbValue}'
        ')';
  }
}
