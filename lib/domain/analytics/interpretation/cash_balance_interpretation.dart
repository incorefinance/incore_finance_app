import 'interpretation_status.dart';

/// Reason keys for Cash Balance Trend interpretation.
/// UI maps these to localized label + explanation.
enum CashBalanceTrendReason {
  /// Balance is stable or growing.
  stableOrGrowing,

  /// Balance dropped significantly from peak.
  droppedFromPeak,

  /// Balance is trending down (last 3 points decreasing).
  trendingDown,

  /// Balance is at or below zero.
  balanceAtOrBelowZero,
}

/// Interpretation result for Cash Balance Trend chart.
/// Domain-only model - no localization dependencies.
class CashBalanceTrendInterpretation {
  /// The status level (healthy, watch, risk).
  final InterpretationStatus status;

  /// The reason key for this interpretation.
  /// UI maps this to localized label + explanation.
  final CashBalanceTrendReason reason;

  const CashBalanceTrendInterpretation({
    required this.status,
    required this.reason,
  });
}
