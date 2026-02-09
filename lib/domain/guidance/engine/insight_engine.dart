import '../../analytics/interpretation/interpretation_status.dart';
import '../../onboarding/income_type.dart';
import '../insight.dart';
import '../insights/low_cash_buffer_insight.dart';
import '../insights/low_cash_runway_insight.dart';
import '../insights/missing_income_insight.dart';
import '../insights/expense_spike_insight.dart';

/// Engine that evaluates and picks the top insight to display.
class InsightEngine {
  const InsightEngine();

  /// Pick the highest priority insight based on current financial state.
  /// Returns null if no insights are applicable.
  ///
  /// Priority order:
  /// 1. Low cash buffer (risk > watch)
  /// 2. Low cash runway
  /// 3. Missing income
  /// 4. Expense spike
  Insight? pickTopInsight({
    required InterpretationStatus? cashStatus,
    required double? latestCashBalance,
    required int meaningfulCashPointCount,
    double? avgMonthlyExpense,
    double? recentExpenseTotal,
    double? priorExpenseTotal,
    IncomeType? incomeType,
    double? recentIncomeTotal,
    double? priorIncomeTotal,
  }) {
    // Evaluate low cash buffer insight first (highest priority)
    final lowCashInsight = LowCashBufferInsight.evaluate(
      cashStatus: cashStatus,
      latestBalance: latestCashBalance,
      meaningfulPointCount: meaningfulCashPointCount,
    );

    if (lowCashInsight != null) {
      return lowCashInsight;
    }

    // Evaluate low cash runway insight (second priority)
    if (latestCashBalance != null && avgMonthlyExpense != null) {
      final runwayInsight = LowCashRunwayInsight.evaluate(
        latestCashBalance: latestCashBalance,
        avgMonthlyExpense: avgMonthlyExpense,
      );

      if (runwayInsight != null) {
        return runwayInsight;
      }
    }

    // Evaluate missing income insight (third priority)
    if (recentIncomeTotal != null && priorIncomeTotal != null) {
      final missingIncomeInsight = MissingIncomeInsight.evaluate(
        incomeType: incomeType,
        recentIncomeTotal: recentIncomeTotal,
        priorIncomeTotal: priorIncomeTotal,
      );

      if (missingIncomeInsight != null) {
        return missingIncomeInsight;
      }
    }

    // Evaluate expense spike insight (fourth priority)
    if (recentExpenseTotal != null && priorExpenseTotal != null) {
      final expenseSpikeInsight = ExpenseSpikeInsight.evaluate(
        recentExpenseTotal: recentExpenseTotal,
        priorExpenseTotal: priorExpenseTotal,
      );

      if (expenseSpikeInsight != null) {
        return expenseSpikeInsight;
      }
    }

    return null;
  }
}
