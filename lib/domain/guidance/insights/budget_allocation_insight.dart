import '../../budgeting/smoothed_budget_snapshot.dart';
import '../insight.dart';
import '../insight_id.dart';
import '../insight_severity.dart';
import '../insight_action.dart';

/// Evaluates budget-related insights based on spending vs allocation.
class BudgetAllocationInsight {
  const BudgetAllocationInsight._();

  /// Minimum day of month before budget pacing insights are triggered.
  /// Avoids false positives early in the month.
  static const int minDayForPacing = 7;

  /// Minimum day of month for overspend warnings.
  static const int minDayForOverspend = 10;

  /// Threshold ratio for pacing warning (120% of expected).
  static const double pacingThreshold = 1.2;

  /// Threshold ratio for overspend risk (150% of expected).
  static const double overspendThreshold = 1.5;

  /// Evaluates budget allocation insights.
  ///
  /// Returns the highest priority budget insight, or null if none apply.
  ///
  /// Priority:
  /// 1. budgetOverspend (risk) - spending > 150% of expected
  /// 2. budgetPacing (watch) - spending > 120% of expected
  /// 3. tightBudget (watch) - < 20% of income spendable
  /// 4. volatileIncome (info) - high income variability
  static Insight? evaluate({
    required SmoothedBudgetSnapshot? budget,
    required double currentMonthSpending,
    required int dayOfMonth,
  }) {
    // No budget data - can't evaluate
    if (budget == null || !budget.hasEnoughData) {
      return null;
    }

    // Calculate expected spending for this point in the month
    final expectedSpent = budget.dailySpendable * dayOfMonth;

    // Avoid division by zero
    if (expectedSpent <= 0) {
      // If expected is zero or negative, check for tight budget
      if (budget.isTight) {
        return const Insight(
          id: InsightId.tightBudget,
          severity: InsightSeverity.watch,
          action: InsightAction.reviewExpenses,
        );
      }
      return null;
    }

    final spendRatio = currentMonthSpending / expectedSpent;

    // Check for overspend (highest priority budget insight)
    if (spendRatio > overspendThreshold && dayOfMonth >= minDayForOverspend) {
      return const Insight(
        id: InsightId.budgetOverspend,
        severity: InsightSeverity.risk,
        action: InsightAction.reviewExpenses,
      );
    }

    // Check for pacing issues
    if (spendRatio > pacingThreshold && dayOfMonth >= minDayForPacing) {
      return const Insight(
        id: InsightId.budgetPacing,
        severity: InsightSeverity.watch,
        action: InsightAction.reviewExpenses,
      );
    }

    // Check for tight budget (low priority)
    if (budget.isTight) {
      return const Insight(
        id: InsightId.tightBudget,
        severity: InsightSeverity.watch,
        action: InsightAction.reviewExpenses,
      );
    }

    // Check for high income volatility (informational)
    if (budget.isHighlyVolatile) {
      return const Insight(
        id: InsightId.volatileIncome,
        severity: InsightSeverity.info,
      );
    }

    return null;
  }
}
