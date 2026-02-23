import 'dart:math';

import '../../models/recurring_expense.dart';
import '../../models/transaction_record.dart';
import '../onboarding/income_type.dart';
import 'income_analysis.dart';
import 'smoothed_budget_snapshot.dart';

/// Pure calculator for smoothed predictive budgeting.
///
/// Computes monthly spendable amounts by:
/// 1. Analyzing income volatility over a lookback period
/// 2. Applying a volatility discount for conservative baseline
/// 3. Deducting tax and safety reserves
/// 4. Deducting recurring expenses
///
/// No repository or localization dependencies.
/// All inputs are sanitized: NaN becomes 0, percentages clamped to [0, 1].
class SmoothedBudgetCalculator {
  const SmoothedBudgetCalculator();

  /// Default lookback period for income analysis (in months).
  static const int defaultLookbackMonths = 6;

  /// Decay factor for weighted average (each prior month is weighted * this).
  static const double weightDecay = 0.85;

  /// Maximum multiplier for outlier capping (values above 2.5x median are capped).
  static const double outlierCapMultiplier = 2.5;

  /// Computes a [SmoothedBudgetSnapshot] from transaction history and settings.
  SmoothedBudgetSnapshot compute({
    required DateTime now,
    required List<TransactionRecord> transactions,
    required List<RecurringExpense> recurringExpenses,
    required IncomeType incomeType,
    required double taxReservePercent,
    required double safetyReservePercent,
    int lookbackMonths = defaultLookbackMonths,
  }) {
    // --- Sanitize percentages ---
    final taxPct = _sanitize(taxReservePercent).clamp(0.0, 1.0);
    final safetyPct = _sanitize(safetyReservePercent).clamp(0.0, 1.0);
    final lookback = lookbackMonths.clamp(2, 24);

    // --- Analyze income ---
    final incomeAnalysis = _analyzeIncome(transactions, now, lookback);

    // --- Apply volatility discount ---
    final volatilityDiscount = _computeVolatilityDiscount(
      incomeAnalysis,
      incomeType,
    );
    final smoothedIncome =
        incomeAnalysis.weightedAverageIncome * volatilityDiscount;

    // --- Calculate reserves ---
    final taxReserve = smoothedIncome * taxPct;
    final safetyReserve = smoothedIncome * safetyPct;
    final totalReserves = taxReserve + safetyReserve;

    // --- Calculate recurring expenses ---
    final monthlyRecurring = recurringExpenses
        .where((e) => e.isActive)
        .fold(0.0, (sum, e) => sum + _sanitize(e.amount));

    // --- Calculate variable expenses estimate ---
    final variableExpenses = _estimateVariableExpenses(transactions, now, 3);

    // --- Final spendable ---
    final monthlySpendable =
        max(0.0, smoothedIncome - totalReserves - monthlyRecurring);

    // --- Determine confidence ---
    final confidence = _determineConfidence(incomeAnalysis.monthsAnalyzed);

    return SmoothedBudgetSnapshot(
      rawMonthlyIncome: incomeAnalysis.averageMonthlyIncome,
      smoothedMonthlyIncome: smoothedIncome,
      volatilityDiscount: volatilityDiscount,
      incomeVolatility: incomeAnalysis.coefficientOfVariation,
      incomePattern: incomeAnalysis.pattern,
      taxReserve: taxReserve,
      taxReservePercent: taxPct,
      safetyReserve: safetyReserve,
      safetyReservePercent: safetyPct,
      monthlyRecurringExpenses: monthlyRecurring,
      estimatedVariableExpenses: variableExpenses,
      monthlySpendable: monthlySpendable,
      confidence: confidence,
      monthsOfIncomeData: incomeAnalysis.monthsWithIncome,
      incomeType: incomeType,
      computedAt: now,
    );
  }

  /// Analyzes income transactions over the lookback period.
  ///
  /// Includes the current month (index 0) plus [lookbackMonths] prior months.
  /// Current month is included so new users with only current-month data
  /// can still see budget estimates.
  IncomeAnalysis _analyzeIncome(
    List<TransactionRecord> transactions,
    DateTime now,
    int lookbackMonths,
  ) {
    // Build month boundaries (i=0 is current month, i=1 is last month, etc.)
    final monthlyIncomes = <MonthlyIncome>[];

    for (int i = 0; i <= lookbackMonths; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      // For current month (i=0), use now as the end boundary to only count up to today
      final monthEnd = i == 0
          ? DateTime(now.year, now.month, now.day + 1)
          : DateTime(now.year, now.month - i + 1, 1);

      double total = 0.0;
      int count = 0;

      for (final tx in transactions) {
        if (tx.type.toLowerCase() != 'income') continue;
        final d = DateTime(tx.date.year, tx.date.month, tx.date.day);

        if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
          total += _sanitize(tx.amount.abs());
          count++;
        }
      }

      monthlyIncomes.add(MonthlyIncome(
        monthStart: monthStart,
        totalIncome: total,
        transactionCount: count,
      ));
    }

    // Filter to months with data for stats (exclude months before first income)
    final hasAnyIncome = monthlyIncomes.any((m) => m.hasIncome);
    if (!hasAnyIncome || monthlyIncomes.isEmpty) {
      return IncomeAnalysis(
        monthlyIncomes: monthlyIncomes,
        averageMonthlyIncome: 0.0,
        weightedAverageIncome: 0.0,
        standardDeviation: 0.0,
        coefficientOfVariation: 0.0,
        medianMonthlyIncome: 0.0,
        zeroIncomeMonths: monthlyIncomes.length,
        pattern: IncomePattern.unknown,
      );
    }

    // Extract income values and cap outliers
    // Use median of NON-ZERO incomes only to avoid capping all values to 0
    // when there are many zero-income months in the lookback period
    final incomeValues = monthlyIncomes.map((m) => m.totalIncome).toList();
    final nonZeroIncomes = incomeValues.where((v) => v > 0).toList();
    final median = nonZeroIncomes.isNotEmpty ? _median(nonZeroIncomes) : 0.0;
    final cappedValues = incomeValues
        .map((v) => min(v, median * outlierCapMultiplier))
        .toList();

    // Simple average (only over months with income to avoid penalizing new users)
    final nonZeroCapped = cappedValues.where((v) => v > 0).toList();
    final average = nonZeroCapped.isNotEmpty
        ? nonZeroCapped.fold(0.0, (s, v) => s + v) / nonZeroCapped.length
        : 0.0;

    // Weighted average (only over months with income)
    // Zero-income months should NOT drag down the average - we want to estimate
    // typical monthly income, not penalize users for months before they started tracking.
    // The volatility discount and CV calculation handle income risk separately.
    double weightedSum = 0.0;
    double weightTotal = 0.0;
    for (int i = 0; i < cappedValues.length; i++) {
      if (cappedValues[i] > 0) {
        final weight = pow(weightDecay, i).toDouble();
        weightedSum += cappedValues[i] * weight;
        weightTotal += weight;
      }
    }
    final weightedAverage = weightTotal > 0 ? weightedSum / weightTotal : 0.0;

    // Standard deviation
    final variance = cappedValues.fold(
            0.0, (sum, v) => sum + pow(v - average, 2).toDouble()) /
        cappedValues.length;
    final stdDev = sqrt(variance);

    // Coefficient of variation
    final cv = average > 0 ? stdDev / average : 0.0;

    // Zero income months count
    final zeroMonths = monthlyIncomes.where((m) => !m.hasIncome).length;

    // Determine pattern
    final pattern = _determinePattern(cv, zeroMonths, monthlyIncomes.length);

    return IncomeAnalysis(
      monthlyIncomes: monthlyIncomes,
      averageMonthlyIncome: average,
      weightedAverageIncome: weightedAverage,
      standardDeviation: stdDev,
      coefficientOfVariation: cv,
      medianMonthlyIncome: median,
      zeroIncomeMonths: zeroMonths,
      pattern: pattern,
    );
  }

  /// Determines the income pattern based on volatility metrics.
  IncomePattern _determinePattern(
      double cv, int zeroMonths, int totalMonths) {
    if (totalMonths < 2) {
      return IncomePattern.unknown;
    }

    final zeroRatio = zeroMonths / totalMonths;

    // High zero-income ratio indicates irregularity
    if (zeroRatio > 0.3) {
      return IncomePattern.irregular;
    }

    // CV-based classification
    if (cv < 0.15) {
      return IncomePattern.regular;
    } else if (cv < 0.35) {
      return IncomePattern.semiRegular;
    } else {
      return IncomePattern.irregular;
    }
  }

  /// Computes the volatility discount based on CV and income type.
  ///
  /// Fixed income gets no discount (income is predictable).
  /// Variable income discount scales with CV.
  double _computeVolatilityDiscount(
    IncomeAnalysis analysis,
    IncomeType incomeType,
  ) {
    // Fixed income: no discount needed
    if (incomeType == IncomeType.fixed) {
      return 1.0;
    }

    // Not enough data: apply moderate discount as precaution
    if (analysis.monthsAnalyzed < 2) {
      return 0.85;
    }

    final cv = analysis.coefficientOfVariation;

    // Volatility discount table:
    // CV < 0.1: 0% discount (very stable)
    // CV 0.1-0.2: 5% discount (minor variation)
    // CV 0.2-0.3: 10% discount (moderate variation)
    // CV 0.3-0.4: 15% discount (significant variation)
    // CV > 0.4: 20-25% discount (high variation)
    if (cv < 0.1) {
      return 1.0;
    } else if (cv < 0.2) {
      return 0.95;
    } else if (cv < 0.3) {
      return 0.90;
    } else if (cv < 0.4) {
      return 0.85;
    } else if (cv < 0.5) {
      return 0.80;
    } else {
      return 0.75;
    }
  }

  /// Estimates average variable expenses from recent months.
  double _estimateVariableExpenses(
    List<TransactionRecord> transactions,
    DateTime now,
    int lookbackMonths,
  ) {
    double totalExpenses = 0.0;
    int monthsWithExpenses = 0;

    for (int i = 0; i <= lookbackMonths; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = i == 0
          ? DateTime(now.year, now.month, now.day + 1)
          : DateTime(now.year, now.month - i + 1, 1);

      double monthExpenses = 0.0;
      for (final tx in transactions) {
        if (tx.type.toLowerCase() != 'expense') continue;
        // Skip recurring expenses (we handle them separately)
        if (tx.recurringExpenseId != null) continue;

        final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
          monthExpenses += _sanitize(tx.amount.abs());
        }
      }

      if (monthExpenses > 0) {
        totalExpenses += monthExpenses;
        monthsWithExpenses++;
      }
    }

    return monthsWithExpenses > 0 ? totalExpenses / monthsWithExpenses : 0.0;
  }

  /// Determines confidence level based on months of data.
  BudgetConfidence _determineConfidence(int months) {
    if (months < 2) {
      return BudgetConfidence.low;
    } else if (months < 5) {
      return BudgetConfidence.medium;
    } else {
      return BudgetConfidence.high;
    }
  }

  /// Computes the median of a list of values.
  double _median(List<double> values) {
    if (values.isEmpty) return 0.0;

    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
  }

  /// Returns 0.0 for NaN, otherwise the value unchanged.
  static double _sanitize(double v) => v.isNaN ? 0.0 : v;
}
