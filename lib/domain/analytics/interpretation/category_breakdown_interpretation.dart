import 'interpretation_status.dart';

/// Reason keys for Category Breakdown interpretation.
/// UI maps these to localized label + explanation.
enum CategoryBreakdownReason {
  /// Spending/income is diversified across categories.
  diversified,

  /// One category has moderate concentration (40-60%).
  moderatelyConcentrated,

  /// One category is highly concentrated (>= 60%).
  highlyConcentrated,
}

/// Interpretation result for Category Breakdown (Income or Expense).
/// Domain-only model - no localization dependencies.
class CategoryBreakdownInterpretation {
  /// The status level (healthy, watch, risk).
  final InterpretationStatus status;

  /// The reason key for this interpretation.
  /// UI maps this to localized label + explanation.
  final CategoryBreakdownReason reason;

  const CategoryBreakdownInterpretation({
    required this.status,
    required this.reason,
  });
}
