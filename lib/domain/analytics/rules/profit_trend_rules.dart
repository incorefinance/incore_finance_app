import '../interpretation/profit_trend_interpretation.dart';
import '../interpretation/interpretation_status.dart';

/// Rule-based evaluation for Profit Trends chart.
class ProfitTrendRules {
  const ProfitTrendRules._();

  /// Evaluate profit trend data and return interpretation.
  /// Returns null if fewer than 2 meaningful (non-zero) data points.
  ///
  /// Logic:
  /// - risk: latestProfit < 0
  /// - watch: last 3 points strictly decreasing with >= 15% drop
  /// - healthy: otherwise
  static ProfitTrendInterpretation? evaluate({
    required List<Map<String, dynamic>> profitData,
  }) {
    // Extract meaningful profit points (non-null, non-NaN, non-zero)
    final profits = <double>[];
    for (final point in profitData) {
      final profit = (point['profit'] as num?)?.toDouble();
      if (profit != null && !profit.isNaN && profit != 0) {
        profits.add(profit);
      }
    }

    // Need at least 2 meaningful (non-zero) points for analysis
    if (profits.length < 2) {
      return null;
    }

    final latestProfit = profits.last;

    // Rule 1: Risk if latest profit < 0
    if (latestProfit < 0) {
      return const ProfitTrendInterpretation(
        status: InterpretationStatus.risk,
        reason: ProfitTrendReason.negativeProfit,
      );
    }

    // Rule 2: Watch if last 3 points strictly decreasing with >= 15% drop
    if (profits.length >= 3) {
      final len = profits.length;
      final p3 = profits[len - 3];
      final p2 = profits[len - 2];
      final p1 = profits[len - 1]; // latest

      final strictlyDecreasing = p3 > p2 && p2 > p1;
      final absP3 = p3.abs();
      final dropPercent = absP3 > 0 ? (p3 - p1) / absP3 : 0.0;

      if (strictlyDecreasing && dropPercent >= 0.15) {
        return const ProfitTrendInterpretation(
          status: InterpretationStatus.watch,
          reason: ProfitTrendReason.trendingDown,
        );
      }
    }

    // Otherwise healthy
    return const ProfitTrendInterpretation(
      status: InterpretationStatus.healthy,
      reason: ProfitTrendReason.stableOrGrowing,
    );
  }
}
