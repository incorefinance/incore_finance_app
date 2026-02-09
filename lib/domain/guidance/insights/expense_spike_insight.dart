import '../insight.dart';
import '../insight_id.dart';
import '../insight_severity.dart';
import '../insight_action.dart';
import '../rules/expense_spike_rules.dart';

/// Evaluates whether to show an expense spike insight.
class ExpenseSpikeInsight {
  const ExpenseSpikeInsight._();

  /// Returns Insight with severity watch if spike detected, null otherwise.
  static Insight? evaluate({
    required double recentExpenseTotal,
    required double priorExpenseTotal,
  }) {
    final result = ExpenseSpikeRules.evaluate(
      recentExpenseTotal: recentExpenseTotal,
      priorExpenseTotal: priorExpenseTotal,
    );

    if (!result.isSpike) return null;

    return const Insight(
      id: InsightId.expenseSpike,
      severity: InsightSeverity.watch,
      action: InsightAction.reviewExpenses,
    );
  }
}
