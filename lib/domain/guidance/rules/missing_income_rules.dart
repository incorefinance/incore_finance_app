import '../../onboarding/income_type.dart';
import '../insight_severity.dart';

/// Result of missing income evaluation.
class MissingIncomeResult {
  final bool isMissing;
  final InsightSeverity? severity;
  final double recentIncomeTotal;
  final double priorIncomeTotal;

  const MissingIncomeResult({
    required this.isMissing,
    this.severity,
    required this.recentIncomeTotal,
    required this.priorIncomeTotal,
  });
}

/// Pure rule-based evaluation for missing income.
class MissingIncomeRules {
  const MissingIncomeRules._();

  static const double minPriorIncome = 100.0;

  /// Evaluates whether income is missing.
  /// Treats NaN inputs as 0. Always returns a result object.
  ///
  /// Triggers when prior >= 100 and recent == 0.
  /// Severity: fixed/mixed/null -> risk, variable -> watch.
  static MissingIncomeResult evaluate({
    required IncomeType? incomeType,
    required double recentIncomeTotal,
    required double priorIncomeTotal,
  }) {
    // Treat NaN as 0
    final recent = recentIncomeTotal.isNaN ? 0.0 : recentIncomeTotal;
    final prior = priorIncomeTotal.isNaN ? 0.0 : priorIncomeTotal;

    final isMissing = prior >= minPriorIncome && recent == 0;

    if (!isMissing) {
      return MissingIncomeResult(
        isMissing: false,
        severity: null,
        recentIncomeTotal: recent,
        priorIncomeTotal: prior,
      );
    }

    // Determine severity based on income type
    final severity = incomeType == IncomeType.variable
        ? InsightSeverity.watch
        : InsightSeverity.risk;

    return MissingIncomeResult(
      isMissing: true,
      severity: severity,
      recentIncomeTotal: recent,
      priorIncomeTotal: prior,
    );
  }
}
