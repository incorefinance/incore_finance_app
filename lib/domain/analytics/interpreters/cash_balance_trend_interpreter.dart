import '../interpretation/cash_balance_interpretation.dart';
import '../rules/cash_balance_trend_rules.dart';

/// Interprets Cash Balance Trend chart data.
class CashBalanceTrendInterpreter {
  const CashBalanceTrendInterpreter();

  /// Generate interpretation for cash balance trend data.
  /// Returns null if data is insufficient (fewer than 2 meaningful points).
  /// Returns domain-only interpretation (no localization).
  /// UI should map the reason to localized label + explanation.
  CashBalanceTrendInterpretation? interpret({
    required List<Map<String, dynamic>> balanceData,
  }) {
    return CashBalanceTrendRules.evaluate(balanceData: balanceData);
  }
}
