import '../insight_severity.dart';

/// Result of low cash runway evaluation.
class LowCashRunwayResult {
  final bool isTriggered;
  final InsightSeverity? severity;
  final double runwayDays;
  final double latestCashBalance;
  final double avgMonthlyExpense;

  const LowCashRunwayResult({
    required this.isTriggered,
    this.severity,
    required this.runwayDays,
    required this.latestCashBalance,
    required this.avgMonthlyExpense,
  });
}

/// Pure rule-based evaluation for low cash runway.
class LowCashRunwayRules {
  const LowCashRunwayRules._();

  static const double riskDays = 30.0;
  static const double watchDays = 60.0;

  /// Evaluates whether cash runway is dangerously short.
  /// Treats NaN inputs as 0. Returns null-like result if guards fail.
  ///
  /// Runway days = latestCashBalance / (avgMonthlyExpense / 30.0)
  ///
  /// Severity:
  /// - risk if runwayDays < 30
  /// - watch if runwayDays < 60
  /// - null otherwise
  static LowCashRunwayResult evaluate({
    required double latestCashBalance,
    required double avgMonthlyExpense,
  }) {
    final cash = latestCashBalance.isNaN ? 0.0 : latestCashBalance;
    final monthly = avgMonthlyExpense.isNaN ? 0.0 : avgMonthlyExpense;

    // Guard: cash must be positive (low cash buffer handles <= 0 cases)
    // Guard: monthly expense must be positive to compute meaningful runway
    if (cash <= 0 || monthly <= 0) {
      return LowCashRunwayResult(
        isTriggered: false,
        severity: null,
        runwayDays: 0.0,
        latestCashBalance: cash,
        avgMonthlyExpense: monthly,
      );
    }

    final dailyBurn = monthly / 30.0;
    if (dailyBurn <= 0) {
      return LowCashRunwayResult(
        isTriggered: false,
        severity: null,
        runwayDays: 0.0,
        latestCashBalance: cash,
        avgMonthlyExpense: monthly,
      );
    }

    final runwayDays = cash / dailyBurn;

    if (runwayDays < riskDays) {
      return LowCashRunwayResult(
        isTriggered: true,
        severity: InsightSeverity.risk,
        runwayDays: runwayDays,
        latestCashBalance: cash,
        avgMonthlyExpense: monthly,
      );
    }

    if (runwayDays < watchDays) {
      return LowCashRunwayResult(
        isTriggered: true,
        severity: InsightSeverity.watch,
        runwayDays: runwayDays,
        latestCashBalance: cash,
        avgMonthlyExpense: monthly,
      );
    }

    return LowCashRunwayResult(
      isTriggered: false,
      severity: null,
      runwayDays: runwayDays,
      latestCashBalance: cash,
      avgMonthlyExpense: monthly,
    );
  }
}
