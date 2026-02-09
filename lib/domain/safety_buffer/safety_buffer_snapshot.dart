/// Immutable snapshot of a safety buffer calculation.
///
/// Represents how many days/weeks of fixed outflows the user can cover
/// with their available balance after reserving a tax shield.
class SafetyBufferSnapshot {
  /// Days of fixed outflow coverage. Null when monthlyFixedOutflow is 0.
  final int? bufferDays;

  /// Weeks of fixed outflow coverage (1 decimal). Null when bufferDays is null.
  final double? bufferWeeks;

  /// Latest cash balance used as input.
  final double balance;

  /// Balance minus tax shield reserve, floored at 0.
  final double available;

  /// Amount reserved for estimated taxes.
  final double taxShieldReserved;

  /// Monthly income used for calculation.
  final double monthlyInflow;

  /// Monthly fixed outflow from recurring expenses.
  final double monthlyFixedOutflow;

  /// Daily income rate (monthlyInflow / 30).
  final double dailyInflow;

  /// Daily fixed outflow rate (monthlyFixedOutflow / 30).
  final double dailyFixedOutflow;

  /// Daily net cash flow (dailyInflow - dailyFixedOutflow).
  final double dailyNet;

  /// Start of the recent calendar month used for income.
  final DateTime recentMonthStart;

  /// Start of the prior calendar month used for income.
  final DateTime priorMonthStart;

  /// Whether two months of income were averaged.
  final bool usedTwoMonths;

  const SafetyBufferSnapshot({
    required this.bufferDays,
    required this.bufferWeeks,
    required this.balance,
    required this.available,
    required this.taxShieldReserved,
    required this.monthlyInflow,
    required this.monthlyFixedOutflow,
    required this.dailyInflow,
    required this.dailyFixedOutflow,
    required this.dailyNet,
    required this.recentMonthStart,
    required this.priorMonthStart,
    required this.usedTwoMonths,
  });
}
