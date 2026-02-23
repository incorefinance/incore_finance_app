import '../onboarding/income_type.dart';
import 'income_analysis.dart';

/// Confidence level for budget calculations based on data availability.
enum BudgetConfidence {
  /// Less than 2 months of income data.
  low,

  /// 2-4 months of income data.
  medium,

  /// 5+ months of income data.
  high,
}

/// Immutable snapshot of a smoothed budget calculation.
///
/// Represents the predictive budget allocation derived from income analysis,
/// applying volatility discounts and reserve deductions.
class SmoothedBudgetSnapshot {
  // ─── Income Metrics ─────────────────────────────────────────────────────────

  /// Simple average of monthly income (no weighting or discounting).
  final double rawMonthlyIncome;

  /// Income after applying volatility discount (conservative baseline).
  final double smoothedMonthlyIncome;

  /// Multiplier applied based on income volatility (0.75-1.0).
  final double volatilityDiscount;

  /// Coefficient of variation of income (stddev/mean).
  final double incomeVolatility;

  /// Detected income pattern (regular, semiRegular, irregular, unknown).
  final IncomePattern incomePattern;

  // ─── Reserves ───────────────────────────────────────────────────────────────

  /// Tax reserve amount: smoothedIncome * taxPercent.
  final double taxReserve;

  /// Tax reserve percentage applied (0.0-1.0).
  final double taxReservePercent;

  /// Safety reserve amount: smoothedIncome * safetyPercent.
  /// Provides buffer for slower income months.
  final double safetyReserve;

  /// Safety reserve percentage applied (0.0-1.0).
  final double safetyReservePercent;

  /// Combined tax + safety reserves.
  double get totalReserves => taxReserve + safetyReserve;

  // ─── Expenses ───────────────────────────────────────────────────────────────

  /// Sum of active recurring bills (monthly commitment).
  final double monthlyRecurringExpenses;

  /// Historical average of variable expenses (non-recurring).
  final double estimatedVariableExpenses;

  // ─── Spendable Amounts ──────────────────────────────────────────────────────

  /// Monthly spendable after all deductions.
  /// = smoothedIncome - totalReserves - monthlyRecurringExpenses
  final double monthlySpendable;

  /// Weekly spending allocation (monthlySpendable / 4).
  double get weeklySpendable => monthlySpendable / 4;

  /// Daily spending allocation (monthlySpendable / 30).
  double get dailySpendable => monthlySpendable / 30;

  // ─── Metadata ───────────────────────────────────────────────────────────────

  /// Confidence level based on months of data available.
  final BudgetConfidence confidence;

  /// Number of months of income data used in analysis.
  final int monthsOfIncomeData;

  /// User's income type from onboarding profile.
  final IncomeType incomeType;

  /// Date when this snapshot was computed.
  final DateTime computedAt;

  // ─── Computed Flags ─────────────────────────────────────────────────────────

  /// Budget is tight if spendable < 20% of raw income.
  bool get isTight => monthlySpendable < (rawMonthlyIncome * 0.2);

  /// Income is highly volatile if CV > 0.4.
  bool get isHighlyVolatile => incomeVolatility > 0.4;

  /// Whether enough data exists for meaningful budget.
  bool get hasEnoughData => monthsOfIncomeData >= 2;

  /// Whether recurring bills exceed smoothed income.
  bool get billsExceedIncome =>
      monthlyRecurringExpenses > (smoothedMonthlyIncome - totalReserves);

  const SmoothedBudgetSnapshot({
    required this.rawMonthlyIncome,
    required this.smoothedMonthlyIncome,
    required this.volatilityDiscount,
    required this.incomeVolatility,
    required this.incomePattern,
    required this.taxReserve,
    required this.taxReservePercent,
    required this.safetyReserve,
    required this.safetyReservePercent,
    required this.monthlyRecurringExpenses,
    required this.estimatedVariableExpenses,
    required this.monthlySpendable,
    required this.confidence,
    required this.monthsOfIncomeData,
    required this.incomeType,
    required this.computedAt,
  });
}
