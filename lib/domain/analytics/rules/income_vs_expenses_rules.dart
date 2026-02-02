import '../interpretation/chart_interpretation.dart';
import '../interpretation/interpretation_status.dart';

/// Rule-based evaluation for Income vs Expenses chart.
class IncomeVsExpensesRules {
  const IncomeVsExpensesRules._();

  /// Minimum income threshold for watch rule to apply.
  /// Avoids silly warnings when income is tiny.
  static const double _minIncomeForWatchRule = 100.0;

  /// Evaluate income vs expenses and return interpretation.
  ///
  /// Logic:
  /// - risk: income <= 0 and expenses > 0 (no income with expenses)
  /// - risk: expenses > income (expenses exceed income)
  /// - watch: expenses >= income * 0.8 AND income >= 100 (meaningful income)
  /// - healthy: otherwise
  static ChartInterpretation evaluate({
    required double income,
    required double expenses,
  }) {
    // Sanitize inputs: treat NaN as 0, clamp to >= 0
    final safeIncome = income.isNaN ? 0.0 : income.clamp(0.0, double.infinity);
    final safeExpenses =
        expenses.isNaN ? 0.0 : expenses.clamp(0.0, double.infinity);

    // No income but has expenses -> risk
    if (safeIncome <= 0 && safeExpenses > 0) {
      return const ChartInterpretation(
        status: InterpretationStatus.risk,
        reason: IncomeVsExpensesReason.noIncomeWithExpenses,
      );
    }

    // Expenses exceed income -> risk
    if (safeExpenses > safeIncome) {
      return const ChartInterpretation(
        status: InterpretationStatus.risk,
        reason: IncomeVsExpensesReason.expensesExceedIncome,
      );
    }

    // Expenses >= 80% of income -> watch (only if income is meaningful)
    if (safeIncome >= _minIncomeForWatchRule &&
        safeExpenses >= safeIncome * 0.8) {
      return const ChartInterpretation(
        status: InterpretationStatus.watch,
        reason: IncomeVsExpensesReason.expensesNearIncome,
      );
    }

    // Otherwise healthy
    return const ChartInterpretation(
      status: InterpretationStatus.healthy,
      reason: IncomeVsExpensesReason.expensesBelowIncome,
    );
  }
}
