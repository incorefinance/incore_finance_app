/// Monthly income data point for analysis.
class MonthlyIncome {
  /// First day of the month this income belongs to.
  final DateTime monthStart;

  /// Total income recorded during this month.
  final double totalIncome;

  /// Number of income transactions in this month.
  final int transactionCount;

  const MonthlyIncome({
    required this.monthStart,
    required this.totalIncome,
    required this.transactionCount,
  });

  /// Whether this month has any income.
  bool get hasIncome => totalIncome > 0;
}

/// Detected income patterns based on statistical analysis.
enum IncomePattern {
  /// Coefficient of variation < 0.15 (salary-like stability).
  regular,

  /// Coefficient of variation 0.15-0.35.
  semiRegular,

  /// Coefficient of variation > 0.35 or >30% zero-income months.
  irregular,

  /// Less than 2 months of data available.
  unknown,
}

/// Analysis of income patterns over a lookback period.
///
/// Used to determine income volatility and appropriate budget smoothing.
class IncomeAnalysis {
  /// Monthly income breakdown for the analysis period.
  final List<MonthlyIncome> monthlyIncomes;

  /// Simple arithmetic mean of monthly incomes.
  final double averageMonthlyIncome;

  /// Weighted average with recent months weighted higher.
  /// Uses exponential decay: most recent month weight 1.0, each prior month * 0.85.
  final double weightedAverageIncome;

  /// Standard deviation of monthly income values.
  final double standardDeviation;

  /// Coefficient of variation (stddev / mean).
  /// 0 = perfectly stable, 1 = high volatility.
  final double coefficientOfVariation;

  /// Median monthly income value.
  final double medianMonthlyIncome;

  /// Count of months with zero income in the analysis period.
  final int zeroIncomeMonths;

  /// Detected income pattern based on CV and zero-income ratio.
  final IncomePattern pattern;

  /// Number of months in the lookback period.
  int get monthsAnalyzed => monthlyIncomes.length;

  /// Number of months that actually have income recorded.
  int get monthsWithIncome => monthlyIncomes.where((m) => m.hasIncome).length;

  /// Ratio of zero-income months to total months.
  double get zeroIncomeRatio =>
      monthsAnalyzed > 0 ? zeroIncomeMonths / monthsAnalyzed : 0.0;

  const IncomeAnalysis({
    required this.monthlyIncomes,
    required this.averageMonthlyIncome,
    required this.weightedAverageIncome,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.medianMonthlyIncome,
    required this.zeroIncomeMonths,
    required this.pattern,
  });
}
