import '../interpretation/category_breakdown_interpretation.dart';
import '../interpretation/interpretation_status.dart';

/// Rule-based evaluation for Category Breakdown (Income or Expense).
class CategoryBreakdownRules {
  const CategoryBreakdownRules._();

  /// Evaluate category breakdown data and return interpretation.
  /// Returns null if no meaningful categories exist.
  ///
  /// Logic based on concentration (highest percentage):
  /// - healthy: top < 40%
  /// - watch: 40% <= top < 60%
  /// - risk: top >= 60%
  static CategoryBreakdownInterpretation? evaluate({
    required List<Map<String, dynamic>> categories,
  }) {
    if (categories.isEmpty) return null;

    double maxShare = 0;

    for (final c in categories) {
      final pct = (c['percentage'] as num?)?.toDouble() ?? 0.0;
      if (pct > maxShare) {
        maxShare = pct;
      }
    }

    // No meaningful data if max share is 0 or less
    if (maxShare <= 0) return null;

    // Risk: highly concentrated (>= 60%)
    if (maxShare >= 60) {
      return const CategoryBreakdownInterpretation(
        status: InterpretationStatus.risk,
        reason: CategoryBreakdownReason.highlyConcentrated,
      );
    }

    // Watch: moderately concentrated (40-60%)
    if (maxShare >= 40) {
      return const CategoryBreakdownInterpretation(
        status: InterpretationStatus.watch,
        reason: CategoryBreakdownReason.moderatelyConcentrated,
      );
    }

    // Healthy: diversified (< 40%)
    return const CategoryBreakdownInterpretation(
      status: InterpretationStatus.healthy,
      reason: CategoryBreakdownReason.diversified,
    );
  }
}
