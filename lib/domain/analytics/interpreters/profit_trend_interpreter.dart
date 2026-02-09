import '../interpretation/profit_trend_interpretation.dart';
import '../rules/profit_trend_rules.dart';

/// Interprets Profit Trends chart data.
class ProfitTrendInterpreter {
  const ProfitTrendInterpreter();

  /// Generate interpretation for profit trend data.
  /// Returns null if data is insufficient (fewer than 2 non-zero points).
  /// Returns domain-only interpretation (no localization).
  /// UI should map the reason to localized label + explanation.
  ProfitTrendInterpretation? interpret({
    required List<Map<String, dynamic>> profitData,
  }) {
    return ProfitTrendRules.evaluate(profitData: profitData);
  }
}
