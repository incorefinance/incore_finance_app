import '../../onboarding/income_type.dart';
import '../insight.dart';
import '../insight_id.dart';
import '../insight_action.dart';
import '../rules/missing_income_rules.dart';

/// Evaluates whether to show a missing income insight.
class MissingIncomeInsight {
  const MissingIncomeInsight._();

  /// Returns Insight if income is missing, null otherwise.
  static Insight? evaluate({
    required IncomeType? incomeType,
    required double recentIncomeTotal,
    required double priorIncomeTotal,
  }) {
    final result = MissingIncomeRules.evaluate(
      incomeType: incomeType,
      recentIncomeTotal: recentIncomeTotal,
      priorIncomeTotal: priorIncomeTotal,
    );

    if (!result.isMissing) return null;

    return Insight(
      id: InsightId.missingIncome,
      severity: result.severity!,
      action: InsightAction.addTransaction,
    );
  }
}
