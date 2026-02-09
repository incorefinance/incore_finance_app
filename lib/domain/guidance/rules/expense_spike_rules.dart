/// Result of expense spike evaluation.
class ExpenseSpikeResult {
  final bool isSpike;
  final double recentExpenseTotal;
  final double priorExpenseTotal;
  final double absoluteIncrease;
  final double percentIncrease;

  const ExpenseSpikeResult({
    required this.isSpike,
    required this.recentExpenseTotal,
    required this.priorExpenseTotal,
    required this.absoluteIncrease,
    required this.percentIncrease,
  });
}

/// Pure rule-based evaluation for expense spikes.
class ExpenseSpikeRules {
  const ExpenseSpikeRules._();

  static const double minPriorExpenses = 100.0;
  static const double minRecentExpenses = 150.0;
  static const double minAbsoluteIncrease = 75.0;
  static const double minPercentIncrease = 35.0;

  /// Evaluates whether an expense spike has occurred.
  /// Treats NaN inputs as 0. Always returns a result object.
  static ExpenseSpikeResult evaluate({
    required double recentExpenseTotal,
    required double priorExpenseTotal,
  }) {
    // Treat NaN as 0
    final recent = recentExpenseTotal.isNaN ? 0.0 : recentExpenseTotal;
    final prior = priorExpenseTotal.isNaN ? 0.0 : priorExpenseTotal;

    final absoluteIncrease = recent - prior;
    final percentIncrease = prior > 0
        ? (absoluteIncrease / prior) * 100
        : 0.0;

    final isSpike = prior >= minPriorExpenses &&
        recent >= minRecentExpenses &&
        absoluteIncrease >= minAbsoluteIncrease &&
        percentIncrease >= minPercentIncrease;

    return ExpenseSpikeResult(
      isSpike: isSpike,
      recentExpenseTotal: recent,
      priorExpenseTotal: prior,
      absoluteIncrease: absoluteIncrease,
      percentIncrease: percentIncrease,
    );
  }
}
