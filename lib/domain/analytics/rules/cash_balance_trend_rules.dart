import '../interpretation/cash_balance_interpretation.dart';
import '../interpretation/interpretation_status.dart';

/// Rule-based evaluation for Cash Balance Trend chart.
class CashBalanceTrendRules {
  const CashBalanceTrendRules._();

  /// Evaluate cash balance trend data and return interpretation.
  /// Returns null if fewer than 2 meaningful data points.
  ///
  /// Logic:
  /// - risk: latestBalance <= 0
  /// - watch: latestBalance <= peakBalance * 0.25 (dropped from peak)
  /// - watch: last 3 points strictly decreasing with >= 15% drop
  /// - healthy: otherwise
  static CashBalanceTrendInterpretation? evaluate({
    required List<Map<String, dynamic>> balanceData,
  }) {
    // Extract meaningful balance points (non-null, non-NaN)
    final balances = <double>[];
    for (final point in balanceData) {
      final balance = (point['balance'] as num?)?.toDouble();
      if (balance != null && !balance.isNaN) {
        balances.add(balance);
      }
    }

    // Need at least 2 meaningful points for analysis
    if (balances.length < 2) {
      return null;
    }

    final latestBalance = balances.last;
    final peakBalance = balances.reduce((a, b) => a > b ? a : b);

    // Rule 1: Risk if latest balance <= 0
    if (latestBalance <= 0) {
      return const CashBalanceTrendInterpretation(
        status: InterpretationStatus.risk,
        reason: CashBalanceTrendReason.balanceAtOrBelowZero,
      );
    }

    // Rule 2a: Watch if latest <= 25% of peak (and peak > 0)
    if (peakBalance > 0 && latestBalance <= peakBalance * 0.25) {
      return const CashBalanceTrendInterpretation(
        status: InterpretationStatus.watch,
        reason: CashBalanceTrendReason.droppedFromPeak,
      );
    }

    // Rule 2b: Watch if last 3 points are strictly decreasing with >= 15% drop
    if (balances.length >= 3) {
      final len = balances.length;
      final p3 = balances[len - 3];
      final p2 = balances[len - 2];
      final p1 = balances[len - 1]; // latest

      final strictlyDecreasing = p3 > p2 && p2 > p1;
      final dropPercent = p3 > 0 ? (p3 - p1) / p3 : 0.0;

      if (strictlyDecreasing && dropPercent >= 0.15) {
        return const CashBalanceTrendInterpretation(
          status: InterpretationStatus.watch,
          reason: CashBalanceTrendReason.trendingDown,
        );
      }
    }

    // Otherwise healthy
    return const CashBalanceTrendInterpretation(
      status: InterpretationStatus.healthy,
      reason: CashBalanceTrendReason.stableOrGrowing,
    );
  }
}
