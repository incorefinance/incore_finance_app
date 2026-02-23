// lib/models/protection_monthly_point.dart
//
// Model for monthly protection ledger series data point.
// Used for sparkline visualization in Protection Coverage card.

/// A single data point representing monthly protection balance change.
class ProtectionMonthlyPoint {
  /// Month key in format "YYYY-MM" (e.g., "2026-02")
  final String monthKey;

  /// Allocation type: 'tax' or 'safety'
  final String allocationType;

  /// Net amount for the month (credits minus debits)
  final double netAmount;

  const ProtectionMonthlyPoint({
    required this.monthKey,
    required this.allocationType,
    required this.netAmount,
  });

  /// Parse from Supabase RPC response map.
  factory ProtectionMonthlyPoint.fromMap(Map<String, dynamic> map) {
    return ProtectionMonthlyPoint(
      monthKey: map['month_key'] as String? ?? '',
      allocationType: map['allocation_type'] as String? ?? '',
      netAmount: _parseDouble(map['net_amount']),
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

  @override
  String toString() {
    return 'ProtectionMonthlyPoint(monthKey: $monthKey, '
        'allocationType: $allocationType, netAmount: $netAmount)';
  }
}
