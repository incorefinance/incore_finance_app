import '../insight.dart';
import '../insight_id.dart';
import '../insight_action.dart';
import '../rules/low_cash_runway_rules.dart';

/// Evaluates whether to show a low cash runway insight.
class LowCashRunwayInsight {
  const LowCashRunwayInsight._();

  /// Returns Insight if runway is dangerously short, null otherwise.
  static Insight? evaluate({
    required double latestCashBalance,
    required double avgMonthlyExpense,
  }) {
    final result = LowCashRunwayRules.evaluate(
      latestCashBalance: latestCashBalance,
      avgMonthlyExpense: avgMonthlyExpense,
    );

    if (!result.isTriggered) return null;

    return Insight(
      id: InsightId.lowCashRunway,
      severity: result.severity!,
      action: InsightAction.reviewExpenses,
    );
  }
}
