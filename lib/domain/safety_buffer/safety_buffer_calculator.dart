import 'dart:math';

import '../tax_shield/tax_shield_snapshot.dart';
import 'safety_buffer_snapshot.dart';

/// Pure calculator for safety buffer metrics.
///
/// Consumes a pre-computed [TaxShieldSnapshot] for income and tax reserve data.
/// No repository or localization dependencies.
class SafetyBufferCalculator {
  const SafetyBufferCalculator();

  /// Maximum buffer days returned (cap).
  static const int maxBufferDays = 180;

  /// Computes a [SafetyBufferSnapshot] from a [TaxShieldSnapshot] and
  /// monthly fixed outflow.
  SafetyBufferSnapshot compute({
    required TaxShieldSnapshot taxShield,
    required double monthlyFixedOutflow,
  }) {
    // --- Sanitize fixed outflow ---
    final fixedOutflow = _sanitize(monthlyFixedOutflow);

    // --- Values from tax shield ---
    final available = taxShield.availableAfterTax;
    final monthlyInflow = taxShield.monthlyInflow;

    // --- Daily rates ---
    final dailyInflow = monthlyInflow / 30.0;
    final dailyFixedOutflow = fixedOutflow / 30.0;
    final dailyNet = dailyInflow - dailyFixedOutflow;

    // --- Buffer days ---
    int? bufferDays;
    double? bufferWeeks;

    if (dailyFixedOutflow <= 0) {
      bufferDays = null;
      bufferWeeks = null;
    } else if (available <= 0) {
      bufferDays = 0;
      bufferWeeks = 0.0;
    } else {
      if (dailyNet >= 0) {
        bufferDays = maxBufferDays;
      } else {
        bufferDays = min(
          (available / dailyNet.abs()).floor(),
          maxBufferDays,
        );
      }
      bufferWeeks =
          double.parse((bufferDays / 7.0).toStringAsFixed(1));
    }

    return SafetyBufferSnapshot(
      bufferDays: bufferDays,
      bufferWeeks: bufferWeeks,
      balance: taxShield.balance,
      available: available,
      taxShieldReserved: taxShield.taxShieldReserved,
      monthlyInflow: monthlyInflow,
      monthlyFixedOutflow: fixedOutflow,
      dailyInflow: dailyInflow,
      dailyFixedOutflow: dailyFixedOutflow,
      dailyNet: dailyNet,
      recentMonthStart: taxShield.recentMonthStart,
      priorMonthStart: taxShield.priorMonthStart,
      usedTwoMonths: taxShield.usedTwoMonths,
    );
  }

  /// Returns 0.0 for NaN, otherwise the value unchanged.
  static double _sanitize(double v) => v.isNaN ? 0.0 : v;
}
