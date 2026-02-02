import '../interpretation/chart_interpretation.dart';
import '../rules/income_vs_expenses_rules.dart';

/// Interprets Income vs Expenses chart data.
class IncomeVsExpensesInterpreter {
  const IncomeVsExpensesInterpreter();

  /// Generate interpretation for income vs expenses values.
  /// Returns domain-only interpretation (no localization).
  /// UI should map the reason to localized label + explanation.
  ChartInterpretation interpret({
    required double income,
    required double expenses,
  }) {
    return IncomeVsExpensesRules.evaluate(
      income: income,
      expenses: expenses,
    );
  }
}
