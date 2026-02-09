import 'dart:math';

import '../../models/transaction_record.dart';
import 'tax_shield_snapshot.dart';

/// Pure calculator for tax shield metrics.
///
/// Computes monthly income from transactions, applies a tax reserve percentage,
/// and returns the available-after-tax balance.
///
/// No repository or localization dependencies.
/// All inputs are sanitized: NaN becomes 0, taxShieldPercent is clamped to [0, 1].
class TaxShieldCalculator {
  const TaxShieldCalculator();

  /// Computes a [TaxShieldSnapshot] from the given financial state.
  TaxShieldSnapshot compute({
    required DateTime now,
    required double latestBalance,
    required List<TransactionRecord> insightTransactions,
    required double taxShieldPercent,
  }) {
    // --- Sanitize all double inputs ---
    final balance = _sanitize(latestBalance);
    final taxPct = _sanitize(taxShieldPercent).clamp(0.0, 1.0);

    // --- Calendar month boundaries ---
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final recentMonthStart =
        DateTime(thisMonthStart.year, thisMonthStart.month - 1, 1);
    final priorMonthStart =
        DateTime(thisMonthStart.year, thisMonthStart.month - 2, 1);
    final recentMonthEnd = thisMonthStart;
    final priorMonthEnd = recentMonthStart;

    // --- Income totals per month ---
    double i1 = 0.0; // recent month
    double i2 = 0.0; // prior month

    for (final tx in insightTransactions) {
      if (tx.type != 'income') continue;
      final amount = _sanitize(tx.amount.abs());
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (!d.isBefore(recentMonthStart) && d.isBefore(recentMonthEnd)) {
        i1 += amount;
      }
      if (!d.isBefore(priorMonthStart) && d.isBefore(priorMonthEnd)) {
        i2 += amount;
      }
    }

    // --- Monthly inflow selection ---
    final bool usedTwoMonths;
    final double monthlyInflow;
    if (i1 > 0 && i2 > 0) {
      monthlyInflow = (i1 + i2) / 2;
      usedTwoMonths = true;
    } else {
      monthlyInflow = i1;
      usedTwoMonths = false;
    }

    // --- Tax shield ---
    final taxShieldReserved = monthlyInflow * taxPct;

    // --- Available after tax ---
    final availableAfterTax = max(0.0, balance - taxShieldReserved);

    return TaxShieldSnapshot(
      monthlyInflow: monthlyInflow,
      taxShieldPercent: taxPct,
      taxShieldReserved: taxShieldReserved,
      balance: balance,
      availableAfterTax: availableAfterTax,
      usedTwoMonths: usedTwoMonths,
      recentMonthStart: recentMonthStart,
      priorMonthStart: priorMonthStart,
    );
  }

  /// Returns 0.0 for NaN, otherwise the value unchanged.
  static double _sanitize(double v) => v.isNaN ? 0.0 : v;
}
