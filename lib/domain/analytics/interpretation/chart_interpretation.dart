import 'interpretation_status.dart';

/// Reason keys for Income vs Expenses interpretation.
/// UI maps these to localized label + explanation.
enum IncomeVsExpensesReason {
  /// Expenses are well below income.
  expensesBelowIncome,

  /// Expenses are close to income (>= 80%).
  expensesNearIncome,

  /// Expenses exceed income.
  expensesExceedIncome,

  /// No income but has expenses.
  noIncomeWithExpenses,
}

/// Represents the interpretation of a chart's data.
/// Domain-only model - no localization dependencies.
class ChartInterpretation {
  /// The status level (healthy, watch, risk).
  final InterpretationStatus status;

  /// The reason key for this interpretation.
  /// UI maps this to localized label + explanation.
  final IncomeVsExpensesReason reason;

  const ChartInterpretation({
    required this.status,
    required this.reason,
  });
}
