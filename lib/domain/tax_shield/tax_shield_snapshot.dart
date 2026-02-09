/// Immutable snapshot of a tax shield calculation.
///
/// Represents the estimated tax reserve and available-after-tax balance
/// derived from recent monthly income.
class TaxShieldSnapshot {
  /// Computed monthly income (average of two months, or recent month only).
  final double monthlyInflow;

  /// Tax shield rate applied, clamped to [0.0, 1.0].
  final double taxShieldPercent;

  /// Amount reserved for estimated taxes: `monthlyInflow * taxShieldPercent`.
  final double taxShieldReserved;

  /// Raw cash balance used as input.
  final double balance;

  /// Balance minus tax shield reserve, floored at 0:
  /// `max(0, balance - taxShieldReserved)`.
  final double availableAfterTax;

  /// Whether two months of income were averaged.
  final bool usedTwoMonths;

  /// Start of the recent calendar month used for income.
  final DateTime recentMonthStart;

  /// Start of the prior calendar month used for income.
  final DateTime priorMonthStart;

  const TaxShieldSnapshot({
    required this.monthlyInflow,
    required this.taxShieldPercent,
    required this.taxShieldReserved,
    required this.balance,
    required this.availableAfterTax,
    required this.usedTwoMonths,
    required this.recentMonthStart,
    required this.priorMonthStart,
  });
}
