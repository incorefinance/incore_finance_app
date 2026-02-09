import '../../../models/transaction_record.dart';
import '../../../services/transactions_repository.dart';
import '../../../services/user_financial_baseline_repository.dart';
import '../../../services/recurring_expenses_repository.dart';
import '../../../domain/analytics/interpreters/cash_balance_trend_interpreter.dart';
import '../../../domain/analytics/interpretation/interpretation_status.dart';
import '../../../domain/safety_buffer/safety_buffer_snapshot.dart';
import '../../../domain/safety_buffer/safety_buffer_calculator.dart';
import '../../../domain/tax_shield/tax_shield_snapshot.dart';
import '../../../domain/tax_shield/tax_shield_calculator.dart';
import '../../../data/settings/tax_shield_settings_store.dart';

/// Immutable data class holding all prepared insight data.
/// Contains only computed outputs - no raw transaction lists.
class InsightPreparedData {
  /// 90-day balance series for cash trend interpretation.
  /// Each entry: {'date': DateTime, 'balance': double}
  final List<Map<String, dynamic>> insightBalanceData;

  /// Expense totals for expense spike insight.
  final double recentExpenseTotal;
  final double priorExpenseTotal;
  final DateTime expenseSpikeRecentMonthStart;
  final DateTime expenseSpikePriorMonthStart;

  /// Computed explainability values for expense spike.
  final double expenseSpikeAbsoluteIncrease;
  final double expenseSpikePercentIncrease;

  /// Income totals for missing income insight.
  final double recentIncomeTotal;
  final double priorIncomeTotal;
  final DateTime missingIncomeRecentMonthStart;
  final DateTime missingIncomePriorMonthStart;

  /// Average monthly expense for runway calculation (2-3 full months).
  /// Null if insufficient data.
  final double? avgMonthlyExpenseForRunway;

  // Evidence values for low cash buffer
  final bool lowCashBufferHasDownTrend;
  final int? lowCashBufferDownTrendStreakDays;

  // Evidence values for low cash runway
  final int? lowCashRunwayMonthsUsed;
  final double? lowCashRunwayAvgDailyBurn;

  // Evidence values for missing income
  final int missingIncomeRecentTxCount;
  final int missingIncomePriorTxCount;

  // Evidence values for expense spike
  final int expenseSpikeRecentTxCount;
  final int expenseSpikePriorTxCount;

  // Tax shield
  final TaxShieldSnapshot? taxShield;

  // Safety buffer
  final double monthlyFixedOutflow;
  final SafetyBufferSnapshot? safetyBuffer;

  const InsightPreparedData({
    required this.insightBalanceData,
    required this.recentExpenseTotal,
    required this.priorExpenseTotal,
    required this.expenseSpikeRecentMonthStart,
    required this.expenseSpikePriorMonthStart,
    required this.expenseSpikeAbsoluteIncrease,
    required this.expenseSpikePercentIncrease,
    required this.recentIncomeTotal,
    required this.priorIncomeTotal,
    required this.missingIncomeRecentMonthStart,
    required this.missingIncomePriorMonthStart,
    required this.avgMonthlyExpenseForRunway,
    required this.lowCashBufferHasDownTrend,
    required this.lowCashBufferDownTrendStreakDays,
    required this.lowCashRunwayMonthsUsed,
    required this.lowCashRunwayAvgDailyBurn,
    required this.missingIncomeRecentTxCount,
    required this.missingIncomePriorTxCount,
    required this.expenseSpikeRecentTxCount,
    required this.expenseSpikePriorTxCount,
    required this.taxShield,
    required this.monthlyFixedOutflow,
    required this.safetyBuffer,
  });
}

/// Prepares all data needed for insight evaluation.
/// Uses fixed time windows independent of chart range.
class InsightDataPreparer {
  final TransactionsRepository _transactionsRepository;
  final UserFinancialBaselineRepository _baselineRepository;
  final RecurringExpensesRepository _recurringExpensesRepository;
  final int transactionLookbackDays;
  final int balanceLookbackDays;
  final double taxShieldPercent;

  InsightDataPreparer({
    required TransactionsRepository transactionsRepository,
    required UserFinancialBaselineRepository baselineRepository,
    required RecurringExpensesRepository recurringExpensesRepository,
    this.transactionLookbackDays = 180,
    this.balanceLookbackDays = 90,
    this.taxShieldPercent = TaxShieldSettingsStore.defaultPercent,
  })  : _transactionsRepository = transactionsRepository,
        _baselineRepository = baselineRepository,
        _recurringExpensesRepository = recurringExpensesRepository;

  /// Prepares all insight data using fixed time windows.
  Future<InsightPreparedData> prepare({required DateTime now}) async {
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 1. Fetch insight transactions (180-day lookback) - kept private, not returned
    final insightTransactions = await _fetchInsightTransactions(now, endDate);

    // 2. Compute expense window totals (calendar months)
    final expenseData = _computeExpenseWindowTotals(insightTransactions, now);

    // Compute explainability values for expense spike
    final absIncrease = expenseData.recentTotal - expenseData.priorTotal;
    final pctIncrease = expenseData.priorTotal > 0
        ? (absIncrease / expenseData.priorTotal) * 100
        : 0.0;

    // 3. Compute income window totals (calendar months)
    final incomeData = _computeIncomeWindowTotals(insightTransactions, now);

    // 4. Compute average monthly expense for runway
    final runwayData =
        _computeAvgMonthlyExpenseForRunway(insightTransactions, now);
    final avgMonthlyExpense = runwayData.avg;
    final lowCashRunwayMonthsUsed = runwayData.monthsUsed;
    final lowCashRunwayAvgDailyBurn =
        avgMonthlyExpense != null ? avgMonthlyExpense / 30.0 : null;

    // 5. Build insight balance data (90-day series)
    final insightBalanceData = await _buildInsightBalanceData(now, endDate);

    // 6. Compute downtrend evidence for low cash buffer
    final downTrendEvidence = _computeDownTrendEvidence(insightBalanceData);

    // 7. Compute monthly fixed outflow from recurring expenses
    final monthlyFixedOutflow = await _computeMonthlyFixedOutflow();

    // 8. Compute tax shield, then safety buffer
    TaxShieldSnapshot? taxShield;
    SafetyBufferSnapshot? safetyBuffer;
    final latestBalance = _extractLatestBalance(insightBalanceData);
    if (latestBalance != null) {
      const taxCalc = TaxShieldCalculator();
      taxShield = taxCalc.compute(
        now: now,
        latestBalance: latestBalance,
        insightTransactions: insightTransactions,
        taxShieldPercent: taxShieldPercent,
      );

      const bufferCalc = SafetyBufferCalculator();
      safetyBuffer = bufferCalc.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: monthlyFixedOutflow,
      );
    }

    return InsightPreparedData(
      insightBalanceData: insightBalanceData,
      recentExpenseTotal: expenseData.recentTotal,
      priorExpenseTotal: expenseData.priorTotal,
      expenseSpikeRecentMonthStart: expenseData.recentMonthStart,
      expenseSpikePriorMonthStart: expenseData.priorMonthStart,
      expenseSpikeAbsoluteIncrease: absIncrease,
      expenseSpikePercentIncrease: pctIncrease,
      recentIncomeTotal: incomeData.recentTotal,
      priorIncomeTotal: incomeData.priorTotal,
      missingIncomeRecentMonthStart: incomeData.recentMonthStart,
      missingIncomePriorMonthStart: incomeData.priorMonthStart,
      avgMonthlyExpenseForRunway: avgMonthlyExpense,
      lowCashBufferHasDownTrend: downTrendEvidence.hasDownTrend,
      lowCashBufferDownTrendStreakDays: downTrendEvidence.streakDays,
      lowCashRunwayMonthsUsed: lowCashRunwayMonthsUsed,
      lowCashRunwayAvgDailyBurn: lowCashRunwayAvgDailyBurn,
      missingIncomeRecentTxCount: incomeData.recentCount,
      missingIncomePriorTxCount: incomeData.priorCount,
      expenseSpikeRecentTxCount: expenseData.recentCount,
      expenseSpikePriorTxCount: expenseData.priorCount,
      taxShield: taxShield,
      monthlyFixedOutflow: monthlyFixedOutflow,
      safetyBuffer: safetyBuffer,
    );
  }

  /// Fetches transactions for insight evaluation with fixed lookback.
  Future<List<TransactionRecord>> _fetchInsightTransactions(
      DateTime now, DateTime endDate) async {
    final insightStartDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: transactionLookbackDays));
    try {
      return await _transactionsRepository.getTransactionsByDateRangeTyped(
          insightStartDate, endDate);
    } catch (_) {
      return [];
    }
  }

  /// Computes expense totals for full calendar months.
  /// Returns (recentTotal, priorTotal, recentMonthStart, priorMonthStart, recentCount, priorCount).
  ({
    double recentTotal,
    double priorTotal,
    DateTime recentMonthStart,
    DateTime priorMonthStart,
    int recentCount,
    int priorCount
  }) _computeExpenseWindowTotals(
      List<TransactionRecord> transactions, DateTime now) {
    // This month start (e.g., Feb 1 if today is Feb 2)
    final thisMonthStart = DateTime(now.year, now.month, 1);

    // Last full month (e.g., Jan 1 - Jan 31 if today is Feb 2)
    final lastMonthStart = thisMonthStart.month == 1
        ? DateTime(thisMonthStart.year - 1, 12, 1)
        : DateTime(thisMonthStart.year, thisMonthStart.month - 1, 1);
    final lastMonthEnd = thisMonthStart; // exclusive end

    // Prior month (e.g., Dec 1 - Dec 31 if today is Feb 2)
    final priorMonthStart = lastMonthStart.month == 1
        ? DateTime(lastMonthStart.year - 1, 12, 1)
        : DateTime(lastMonthStart.year, lastMonthStart.month - 1, 1);
    final priorMonthEnd = lastMonthStart; // exclusive end

    double lastMonthTotal = 0.0;
    double priorMonthTotal = 0.0;
    int lastMonthCount = 0;
    int priorMonthCount = 0;

    for (final tx in transactions) {
      if (tx.type != 'expense') continue;
      final amount = tx.amount.abs();
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);

      // Last full month: lastMonthStart inclusive to lastMonthEnd exclusive
      if (!d.isBefore(lastMonthStart) && d.isBefore(lastMonthEnd)) {
        lastMonthTotal += amount;
        lastMonthCount++;
      }
      // Prior month: priorMonthStart inclusive to priorMonthEnd exclusive
      if (!d.isBefore(priorMonthStart) && d.isBefore(priorMonthEnd)) {
        priorMonthTotal += amount;
        priorMonthCount++;
      }
    }

    return (
      recentTotal: lastMonthTotal,
      priorTotal: priorMonthTotal,
      recentMonthStart: lastMonthStart,
      priorMonthStart: priorMonthStart,
      recentCount: lastMonthCount,
      priorCount: priorMonthCount,
    );
  }

  /// Computes income totals for full calendar months.
  /// Returns (recentTotal, priorTotal, recentMonthStart, priorMonthStart, recentCount, priorCount).
  ({
    double recentTotal,
    double priorTotal,
    DateTime recentMonthStart,
    DateTime priorMonthStart,
    int recentCount,
    int priorCount
  }) _computeIncomeWindowTotals(
      List<TransactionRecord> transactions, DateTime now) {
    // This month start (e.g., Feb 1 if today is Feb 2)
    final thisMonthStart = DateTime(now.year, now.month, 1);

    // Last full month (e.g., Jan 1 - Jan 31 if today is Feb 2)
    final lastMonthStart = thisMonthStart.month == 1
        ? DateTime(thisMonthStart.year - 1, 12, 1)
        : DateTime(thisMonthStart.year, thisMonthStart.month - 1, 1);
    final lastMonthEnd = thisMonthStart; // exclusive end

    // Prior month (e.g., Dec 1 - Dec 31 if today is Feb 2)
    final priorMonthStart = lastMonthStart.month == 1
        ? DateTime(lastMonthStart.year - 1, 12, 1)
        : DateTime(lastMonthStart.year, lastMonthStart.month - 1, 1);
    final priorMonthEnd = lastMonthStart; // exclusive end

    double lastMonthTotal = 0.0;
    double priorMonthTotal = 0.0;
    int lastMonthCount = 0;
    int priorMonthCount = 0;

    for (final tx in transactions) {
      if (tx.type != 'income') continue;
      final amount = tx.amount.abs();
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);

      // Last full month: lastMonthStart inclusive to lastMonthEnd exclusive
      if (!d.isBefore(lastMonthStart) && d.isBefore(lastMonthEnd)) {
        lastMonthTotal += amount;
        lastMonthCount++;
      }
      // Prior month: priorMonthStart inclusive to priorMonthEnd exclusive
      if (!d.isBefore(priorMonthStart) && d.isBefore(priorMonthEnd)) {
        priorMonthTotal += amount;
        priorMonthCount++;
      }
    }

    return (
      recentTotal: lastMonthTotal,
      priorTotal: priorMonthTotal,
      recentMonthStart: lastMonthStart,
      priorMonthStart: priorMonthStart,
      recentCount: lastMonthCount,
      priorCount: priorMonthCount,
    );
  }

  /// Computes average monthly expense from the last 2-3 full calendar months.
  /// Returns (avg, monthsUsed) or (null, null) if fewer than 2 months have meaningful expense data.
  ({double? avg, int? monthsUsed}) _computeAvgMonthlyExpenseForRunway(
      List<TransactionRecord> transactions, DateTime now) {
    final currentMonthStart = DateTime(now.year, now.month, 1);

    // Build list of up to 3 full months before current month
    final monthTotals = <double>[];

    for (int i = 1; i <= 3; i++) {
      // Calculate month start by going back i months
      var targetMonth = currentMonthStart.month - i;
      var targetYear = currentMonthStart.year;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      final monthStart = DateTime(targetYear, targetMonth, 1);

      // Calculate month end (start of next month)
      final nextMonth = targetMonth == 12 ? 1 : targetMonth + 1;
      final nextYear = targetMonth == 12 ? targetYear + 1 : targetYear;
      final monthEnd = DateTime(nextYear, nextMonth, 1);

      // Sum expenses in this month
      double monthTotal = 0.0;
      for (final tx in transactions) {
        if (tx.type != 'expense') continue;
        final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
          monthTotal += tx.amount.abs();
        }
      }

      // Only include months with meaningful expense data
      if (monthTotal > 0) {
        monthTotals.add(monthTotal);
      }
    }

    // Need at least 2 months of data
    if (monthTotals.length < 2) {
      return (avg: null, monthsUsed: null);
    }

    // Return average and months used
    final sum = monthTotals.reduce((a, b) => a + b);
    return (avg: sum / monthTotals.length, monthsUsed: monthTotals.length);
  }

  /// Computes downtrend evidence from insight balance data.
  ({bool hasDownTrend, int? streakDays}) _computeDownTrendEvidence(
      List<Map<String, dynamic>> balanceData) {
    if (balanceData.length < 2) {
      return (hasDownTrend: false, streakDays: null);
    }

    // Use CashBalanceTrendInterpreter to determine if downtrend exists
    const interpreter = CashBalanceTrendInterpreter();
    final interp = interpreter.interpret(balanceData: balanceData);

    final hasDownTrend = interp != null &&
        (interp.status == InterpretationStatus.watch ||
         interp.status == InterpretationStatus.risk);

    // Compute streak: consecutive days decreasing at end of series
    int streak = 0;
    for (int i = balanceData.length - 1; i > 0; i--) {
      final curr = (balanceData[i]['balance'] as num?)?.toDouble();
      final prev = (balanceData[i - 1]['balance'] as num?)?.toDouble();
      if (curr == null || prev == null) break;
      if (prev > curr) {
        streak++;
      } else {
        break;
      }
    }
    // Cap to 30 to avoid silly numbers
    final cappedStreak = streak > 30 ? 30 : streak;

    return (hasDownTrend: hasDownTrend, streakDays: cappedStreak);
  }

  /// Computes total monthly fixed outflow from active recurring expenses.
  Future<double> _computeMonthlyFixedOutflow() async {
    try {
      final expenses =
          await _recurringExpensesRepository.getActiveRecurringExpenses();
      double total = 0.0;
      for (final e in expenses) {
        total += e.amount.abs();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  /// Extracts the latest non-null, non-NaN balance from a balance series.
  double? _extractLatestBalance(List<Map<String, dynamic>> balanceData) {
    for (int i = balanceData.length - 1; i >= 0; i--) {
      final b = (balanceData[i]['balance'] as num?)?.toDouble();
      if (b != null && !b.isNaN) return b;
    }
    return null;
  }

  /// Builds insight balance data (fixed 90-day series).
  Future<List<Map<String, dynamic>>> _buildInsightBalanceData(
      DateTime now, DateTime endDate) async {
    try {
      final days = balanceLookbackDays;

      final startDate = endDate.subtract(Duration(days: days - 1));
      final startDateNormalized =
          DateTime(startDate.year, startDate.month, startDate.day);

      // Fetch starting balance from user_financial_baseline
      double startingBalance = 0.0;
      try {
        final baseline = await _baselineRepository.getBaselineForCurrentUser();
        if (baseline != null) {
          startingBalance = baseline.startingBalance;
        }
      } catch (_) {
        // Keep startingBalance as 0 if fetch fails
      }

      // Fetch all transactions BEFORE the insight period to compute pre-period balance
      final allTransactionsBeforeStart =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        DateTime(2000, 1, 1),
        startDateNormalized.subtract(const Duration(days: 1)),
      );

      double prePeriodNet = 0.0;
      for (final tx in allTransactionsBeforeStart) {
        prePeriodNet += tx.type == 'income' ? tx.amount : -tx.amount;
      }

      final chartBaseline = startingBalance + prePeriodNet;

      final transactions =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        startDateNormalized,
        endDate,
      );

      final Map<String, double> dailyNetChanges = {};

      for (int i = 0; i < days; i++) {
        final date = startDateNormalized.add(Duration(days: i));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyNetChanges[key] = 0.0;
      }

      for (final tx in transactions) {
        final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        if (!dailyNetChanges.containsKey(key)) continue;

        dailyNetChanges[key] = (dailyNetChanges[key] ?? 0) +
            (tx.type == 'income' ? tx.amount : -tx.amount);
      }

      final List<Map<String, dynamic>> series = [];
      double runningBalance = chartBaseline;

      for (int i = 0; i < days; i++) {
        final date = startDateNormalized.add(Duration(days: i));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        runningBalance += dailyNetChanges[key] ?? 0;
        series.add({'date': date, 'balance': runningBalance});
      }

      return series;
    } catch (_) {
      return [];
    }
  }
}
