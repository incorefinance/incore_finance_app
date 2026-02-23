import '../../analytics/interpretation/interpretation_status.dart';
import '../../budgeting/smoothed_budget_snapshot.dart';
import '../../onboarding/income_type.dart';
import '../insight.dart';
import '../insight_severity.dart';
import '../insights/low_cash_buffer_insight.dart';
import '../insights/low_cash_runway_insight.dart';
import '../insights/missing_income_insight.dart';
import '../insights/expense_spike_insight.dart';
import '../insights/budget_allocation_insight.dart';

/// Engine that evaluates and picks the top insight to display.
class InsightEngine {
  const InsightEngine();

  /// Pick the highest priority insight based on current financial state.
  /// Returns null if no insights are applicable.
  ///
  /// Priority order:
  /// 1. Low cash buffer (risk > watch)
  /// 2. Low cash runway
  /// 3. Budget overspend (risk)
  /// 4. Missing income
  /// 5. Expense spike
  /// 6. Budget pacing (watch)
  /// 7. Tight budget (watch)
  /// 8. Volatile income (info)
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
    SmoothedBudgetSnapshot? budgetSnapshot,
    double? currentMonthSpending,
    int? dayOfMonth,
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

    // Evaluate budget overspend insight (third priority - risk level only)
    if (budgetSnapshot != null &&
        currentMonthSpending != null &&
        dayOfMonth != null) {
      final budgetInsight = BudgetAllocationInsight.evaluate(
        budget: budgetSnapshot,
        currentMonthSpending: currentMonthSpending,
        dayOfMonth: dayOfMonth,
      );

      // Only return risk-level budget insights at this priority
      if (budgetInsight != null &&
          budgetInsight.severity == InsightSeverity.risk) {
        return budgetInsight;
      }
    }

    // Evaluate missing income insight (fourth priority)
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

    // Evaluate expense spike insight (fifth priority)
    if (recentExpenseTotal != null && priorExpenseTotal != null) {
      final expenseSpikeInsight = ExpenseSpikeInsight.evaluate(
        recentExpenseTotal: recentExpenseTotal,
        priorExpenseTotal: priorExpenseTotal,
      );

      if (expenseSpikeInsight != null) {
        return expenseSpikeInsight;
      }
    }

    // Evaluate budget pacing/tight/volatile insights (lower priority - watch/info)
    if (budgetSnapshot != null &&
        currentMonthSpending != null &&
        dayOfMonth != null) {
      final budgetInsight = BudgetAllocationInsight.evaluate(
        budget: budgetSnapshot,
        currentMonthSpending: currentMonthSpending,
        dayOfMonth: dayOfMonth,
      );

      // Return watch/info level budget insights
      if (budgetInsight != null) {
        return budgetInsight;
      }
    }

    return null;
  }
}
