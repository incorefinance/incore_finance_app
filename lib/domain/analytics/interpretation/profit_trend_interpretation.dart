import 'interpretation_status.dart';

/// Reason keys for Profit Trend interpretation.
/// UI maps these to localized label + explanation.
enum ProfitTrendReason {
  /// Profit is stable or growing.
  stableOrGrowing,

  /// Profit is trending down (last 3 points decreasing).
  trendingDown,

  /// Latest profit is negative.
  negativeProfit,
}

/// Interpretation result for Profit Trends chart.
/// Domain-only model - no localization dependencies.
class ProfitTrendInterpretation {
  /// The status level (healthy, watch, risk).
  final InterpretationStatus status;

  /// The reason key for this interpretation.
  /// UI maps this to localized label + explanation.
  final ProfitTrendReason reason;

  const ProfitTrendInterpretation({
    required this.status,
    required this.reason,
  });
}
