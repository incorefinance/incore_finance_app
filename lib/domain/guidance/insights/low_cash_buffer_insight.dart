import '../../analytics/interpretation/interpretation_status.dart';
import '../insight.dart';
import '../insight_id.dart';
import '../insight_severity.dart';
import '../insight_action.dart';

/// Evaluates whether to show a low cash buffer insight.
/// Pure rule-based, no localization dependencies.
class LowCashBufferInsight {
  const LowCashBufferInsight._();

  /// Evaluate cash status and balance to determine insight.
  ///
  /// Rules:
  /// - Requires at least 2 meaningful (non-zero) data points
  /// - If latestBalance <= 0 OR cashStatus is risk → return risk severity
  /// - Else if cashStatus is watch → return watch severity
  /// - Else return null (no insight)
  static Insight? evaluate({
    required InterpretationStatus? cashStatus,
    required double? latestBalance,
    required int meaningfulPointCount,
  }) {
    // Need at least 2 meaningful points to show insight
    if (meaningfulPointCount < 2) return null;

    // No insight if we don't have cash status
    if (cashStatus == null) return null;

    // Risk: balance is zero/negative OR cash status is risk
    if ((latestBalance != null && latestBalance <= 0) ||
        cashStatus == InterpretationStatus.risk) {
      return const Insight(
        id: InsightId.lowCashBuffer,
        severity: InsightSeverity.risk,
        action: InsightAction.reviewExpenses,
      );
    }

    // Watch: cash status is watch
    if (cashStatus == InterpretationStatus.watch) {
      return const Insight(
        id: InsightId.lowCashBuffer,
        severity: InsightSeverity.watch,
        action: InsightAction.reviewExpenses,
      );
    }

    // Healthy - no insight
    return null;
  }
}
