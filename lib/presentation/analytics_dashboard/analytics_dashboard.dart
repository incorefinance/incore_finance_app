import 'package:flutter/material.dart';
import 'package:incore_finance/core/navigation/route_observer.dart';
import 'package:incore_finance/widgets/custom_bottom_bar.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/app_error_classifier.dart';
import '../../core/logging/app_logger.dart';
import '../../services/auth_guard.dart';
import '../../widgets/app_error_widget.dart';
import '../../utils/number_formatter.dart';
import '../../utils/category_localizer.dart';
import '../../l10n/app_localizations.dart';
import './widgets/income_expenses_chart_widget.dart';
import './widgets/profit_trends_chart_widget.dart';
import './widgets/cash_balance_chart.dart';
import './widgets/comparison_metrics_card.dart';
import './widgets/category_tile_card.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_financial_baseline_repository.dart';
import 'package:incore_finance/models/transaction_category.dart';
import 'package:incore_finance/core/state/transactions_change_notifier.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../domain/analytics/interpreters/income_vs_expenses_interpreter.dart';
import '../../domain/analytics/interpreters/cash_balance_trend_interpreter.dart';
import '../../domain/analytics/interpreters/profit_trend_interpreter.dart';
import '../../domain/analytics/interpreters/category_breakdown_interpreter.dart';
import '../../domain/analytics/interpretation/interpretation_status.dart';
import './widgets/chart_card_header.dart';
import './widgets/insight_card.dart';
import './widgets/safety_buffer_section.dart';
import '../../domain/guidance/insight.dart';
import '../../domain/guidance/insight_id.dart';
import '../../domain/guidance/insight_severity.dart';
import '../../domain/guidance/engine/insight_engine.dart';
import '../../data/guidance/insight_state_store.dart';
import '../../data/guidance/shared_prefs_insight_state_store.dart';
import '../../domain/onboarding/income_type.dart';
import '../../data/profile/user_income_repository.dart';
import 'insights/insight_data_preparer.dart';
import '../../domain/safety_buffer/safety_buffer_snapshot.dart';
import '../../domain/tax_shield/tax_shield_snapshot.dart';
import '../../data/settings/tax_shield_settings_store.dart';
import '../../services/recurring_expenses_repository.dart';
import '../../models/recurring_expense.dart';
import '../../data/telemetry/local_event_store.dart';
import './widgets/pressure_relief_banner.dart';

String _dateLocale = 'en_US';

enum _AnalyticsRange { m3, m6, m12 }

/// Holds localized interpretation data for Income vs Expenses chart.
class _IncomeVsExpensesInterpretationData {
  final InterpretationStatus status;
  final String label;
  final String explanation;

  const _IncomeVsExpensesInterpretationData({
    required this.status,
    required this.label,
    required this.explanation,
  });
}

/// Holds localized interpretation data for Cash Balance Trend chart.
class _CashBalanceTrendInterpretationData {
  final InterpretationStatus status;
  final String label;
  final String explanation;

  const _CashBalanceTrendInterpretationData({
    required this.status,
    required this.label,
    required this.explanation,
  });
}

/// Holds localized interpretation data for Profit Trends chart.
class _ProfitTrendInterpretationData {
  final InterpretationStatus status;
  final String label;
  final String explanation;

  const _ProfitTrendInterpretationData({
    required this.status,
    required this.label,
    required this.explanation,
  });
}

/// Holds localized interpretation data for Category Breakdown (Income or Expense).
class _CategoryBreakdownInterpretationData {
  final InterpretationStatus status;
  final String label;
  final String explanation;

  const _CategoryBreakdownInterpretationData({
    required this.status,
    required this.label,
    required this.explanation,
  });
}

/// Analytics Dashboard screen for comprehensive financial insights
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with RouteAware {
  final TransactionsRepository _transactionsRepository = TransactionsRepository();
  final UserFinancialBaselineRepository _baselineRepository =
      UserFinancialBaselineRepository();

  /// Tracks version from TransactionsChangeNotifier to detect data changes.
  int _lastNotifierVersion = 0;

  bool _isLoading = true;
  AppError? _loadError;
  bool _hasNoTransactions = false;

  List<Map<String, dynamic>> _incomeExpensesData = [];
  List<Map<String, dynamic>> _profitTrendsData = [];
  List<Map<String, dynamic>> _incomeCategoryData = [];
  List<Map<String, dynamic>> _expenseCategoryData = [];
  List<Map<String, dynamic>> _fullIncomeCategoryData = [];
  List<Map<String, dynamic>> _fullExpenseCategoryData = [];
  List<Map<String, dynamic>> _balanceData = [];
  Set<int> _transactionDayIndices = {};

  // Month-over-month change data
  double _incomeChange = 0.0;
  double _expenseChange = 0.0;

  _AnalyticsRange _range = _AnalyticsRange.m3;

  final UserSettingsService _settingsService = UserSettingsService();

  // Currency settings
  String _currencyLocale = 'pt_PT';
  String _currencySymbol = '€';
  String _currencyCode = 'EUR';

  // Insight state
  final InsightStateStore _insightStore = SharedPrefsInsightStateStore();
  Insight? _currentInsight;
  DateTime? _currentInsightDismissedUntil;

  // Expense window totals for expense spike insight (calendar month based)
  double _recentExpenseTotal = 0.0;
  double _priorExpenseTotal = 0.0;
  DateTime? _expenseSpikeRecentMonthStart;
  DateTime? _expenseSpikePriorMonthStart;

  // Expense spike explainability values
  double _expenseSpikeAbsoluteIncrease = 0.0;
  double _expenseSpikePercentIncrease = 0.0;

  // Income window totals for missing income insight (calendar month based)
  double _recentIncomeTotal = 0.0;
  double _priorIncomeTotal = 0.0;
  DateTime? _missingIncomeRecentMonthStart;
  DateTime? _missingIncomePriorMonthStart;
  IncomeType? _incomeType;

  // Average monthly expense for runway calculation (last 2-3 full months)
  double? _avgMonthlyExpenseForRunway;

  // Insight-specific balance data (fixed 90-day window, independent of chart range)
  List<Map<String, dynamic>> _insightBalanceData = [];

  // Evidence values for v2 details
  bool _lowCashBufferHasDownTrend = false;
  int? _lowCashBufferDownTrendStreakDays;
  int? _lowCashRunwayMonthsUsed;
  int _missingIncomePriorTxCount = 0;
  int _expenseSpikeRecentTxCount = 0;
  int _expenseSpikePriorTxCount = 0;

  SafetyBufferSnapshot? _safetyBufferSnapshot;
  TaxShieldSnapshot? _taxShieldSnapshot;
  final TaxShieldSettingsStore _taxShieldSettingsStore = TaxShieldSettingsStore();
  double _taxShieldPercent = TaxShieldSettingsStore.defaultPercent;

  final RecurringExpensesRepository _recurringExpensesRepository =
      RecurringExpensesRepository();
  List<RecurringExpense> _activeRecurringExpenses = [];

  // Pressure relief banner + event tracking
  final LocalEventStore _localEventStore = LocalEventStore();
  bool _showPressureRelief = false;
  int _pausedBillsCount = 0;
  DateTime? _pressureReliefShownAt;
  bool _isPressurePointVisible = false;
  bool _checkResolvedAfterPause = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _loadAnalyticsData();

    // Listen for transaction changes to refresh analytics
    _lastNotifierVersion = TransactionsChangeNotifier.instance.version.value;
    TransactionsChangeNotifier.instance.version.addListener(_onTransactionsChanged);
  }

  @override
  void dispose() {
    TransactionsChangeNotifier.instance.version.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouteObserver.instance.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    print('=== Analytics: didPopNext called, reloading for stale state');
    _loadAnalyticsData();
  }

  void _onTransactionsChanged() {
    final currentVersion = TransactionsChangeNotifier.instance.version.value;
    if (currentVersion != _lastNotifierVersion) {
      // ignore: avoid_print
      print('=== Analytics: TransactionsChangeNotifier triggered refresh (version $currentVersion)');
      _lastNotifierVersion = currentVersion;
      _loadAnalyticsData();
    }
  }

  Future<void> _loadUserSettings() async {
    try {
      final settings = await _settingsService.getCurrencySettings();

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('language') ?? 'en'; // 'en' or 'pt'

      if (!mounted) return;

      setState(() {
        _currencyLocale = settings.locale;
        _currencySymbol = settings.symbol;
        _currencyCode = settings.currencyCode;

        // date locale follows app language, not currency
        _dateLocale = (lang == 'pt') ? 'pt_PT' : 'en_US';
      });
    } catch (_) {
      // keep defaults
    }
  }

  void _showRelief({required int pausedCount}) {
    setState(() {
      _showPressureRelief = true;
      _pausedBillsCount = pausedCount;
      _pressureReliefShownAt = DateTime.now();
    });
    Future.delayed(const Duration(seconds: 12), () {
      if (!mounted) return;
      if (_pressureReliefShownAt != null &&
          DateTime.now().difference(_pressureReliefShownAt!).inSeconds >= 12) {
        setState(() => _showPressureRelief = false);
      }
    });
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _hasNoTransactions = false;
    });

    try {
      final now = DateTime.now();
      final months = _range == _AnalyticsRange.m3
          ? 3
          : _range == _AnalyticsRange.m6
              ? 6
              : 12;

      final startMonth = DateTime(now.year, now.month - (months - 1), 1);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final transactions =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        startMonth,
        endDate,
      );

      if (!mounted) return;

      // Check if user has no transactions at all
      final hasData = transactions.isNotEmpty;

      _incomeExpensesData = _buildIncomeExpensesMonthlyData(
        transactions: transactions,
        startMonth: startMonth,
        months: months,
      );

      _profitTrendsData = _buildProfitMonthlyData(
        incomeExpensesMonthlyData: _incomeExpensesData,
      );

      _incomeCategoryData = _buildCategoryBreakdownData(
        transactions: transactions,
        type: 'income',
      );
      _fullIncomeCategoryData = _buildFullCategoryList(
        transactions: transactions,
        type: 'income',
      );

      _expenseCategoryData = _buildCategoryBreakdownData(
        transactions: transactions,
        type: 'expense',
      );
      _fullExpenseCategoryData = _buildFullCategoryList(
        transactions: transactions,
        type: 'expense',
      );

      // Calculate month-over-month changes
      _calculateMonthOverMonthChanges(transactions, now);

      // === Prepare insight-specific data (fixed windows, independent of chart range) ===
      _taxShieldPercent = await _taxShieldSettingsStore.getTaxShieldPercent();
      final prepared = await InsightDataPreparer(
        transactionsRepository: _transactionsRepository,
        baselineRepository: _baselineRepository,
        recurringExpensesRepository: RecurringExpensesRepository(),
        taxShieldPercent: _taxShieldPercent,
      ).prepare(now: now);

      // Store prepared data in state variables
      _insightBalanceData = prepared.insightBalanceData;
      _recentExpenseTotal = prepared.recentExpenseTotal;
      _priorExpenseTotal = prepared.priorExpenseTotal;
      _expenseSpikeRecentMonthStart = prepared.expenseSpikeRecentMonthStart;
      _expenseSpikePriorMonthStart = prepared.expenseSpikePriorMonthStart;
      _expenseSpikeAbsoluteIncrease = prepared.expenseSpikeAbsoluteIncrease;
      _expenseSpikePercentIncrease = prepared.expenseSpikePercentIncrease;
      _recentIncomeTotal = prepared.recentIncomeTotal;
      _priorIncomeTotal = prepared.priorIncomeTotal;
      _missingIncomeRecentMonthStart = prepared.missingIncomeRecentMonthStart;
      _missingIncomePriorMonthStart = prepared.missingIncomePriorMonthStart;
      _avgMonthlyExpenseForRunway = prepared.avgMonthlyExpenseForRunway;
      _lowCashBufferHasDownTrend = prepared.lowCashBufferHasDownTrend;
      _lowCashBufferDownTrendStreakDays = prepared.lowCashBufferDownTrendStreakDays;
      _lowCashRunwayMonthsUsed = prepared.lowCashRunwayMonthsUsed;
      _missingIncomePriorTxCount = prepared.missingIncomePriorTxCount;
      _expenseSpikeRecentTxCount = prepared.expenseSpikeRecentTxCount;
      _expenseSpikePriorTxCount = prepared.expenseSpikePriorTxCount;
      _safetyBufferSnapshot = prepared.safetyBuffer;
      _taxShieldSnapshot = prepared.taxShield;

      // Fetch active recurring expenses for pressure point calculation
      try {
        _activeRecurringExpenses =
            await _recurringExpensesRepository.getActiveRecurringExpenses();
      } catch (_) {
        _activeRecurringExpenses = [];
      }

      // Load income type from user profile
      try {
        final incomeRepository = UserIncomeRepository();
        final (incomeType, _) = await incomeRepository.getIncomeProfile();
        _incomeType = incomeType;
      } catch (_) {
        _incomeType = null;
      }

      // Load cash balance data for charts (range-dependent)
      await _loadCashBalanceData();

      if (!mounted) return;

      // Refresh insight based on current data
      await _refreshInsight();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasNoTransactions = !hasData;
      });
    } catch (e, st) {
      AppLogger.e('Analytics load error', error: e, stackTrace: st);
      final appError = AppErrorClassifier.classify(e, stackTrace: st);

      if (!mounted) return;

      // Route to auth error screen for auth failures
      if (appError.category == AppErrorCategory.auth) {
        AuthGuard.routeToErrorIfInvalid(context, reason: appError.debugReason);
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = appError;
      });
    }
  }

  void _calculateMonthOverMonthChanges(List<TransactionRecord> transactions, DateTime now) {
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final currentMonthEnd = nextMonthStart.subtract(const Duration(milliseconds: 1));

    final prevMonthEnd = currentMonthStart.subtract(const Duration(days: 1));
    final prevMonthStart = DateTime(prevMonthEnd.year, prevMonthEnd.month, 1);

    double currentIncome = 0;
    double currentExpense = 0;
    double prevIncome = 0;
    double prevExpense = 0;

    for (final tx in transactions) {
      final d = tx.date;

      // Current month
      if (!d.isBefore(currentMonthStart) && !d.isAfter(currentMonthEnd)) {
        if (tx.type == 'income') {
          currentIncome += tx.amount;
        } else if (tx.type == 'expense') {
          currentExpense += tx.amount;
        }
      }

      // Previous month
      if (!d.isBefore(prevMonthStart) && !d.isAfter(prevMonthEnd)) {
        if (tx.type == 'income') {
          prevIncome += tx.amount;
        } else if (tx.type == 'expense') {
          prevExpense += tx.amount;
        }
      }
    }

    if (prevIncome != 0) {
      _incomeChange = ((currentIncome - prevIncome) / prevIncome) * 100;
    } else if (currentIncome != 0) {
      _incomeChange = 100.0;
    } else {
      _incomeChange = 0.0;
    }

    if (prevExpense != 0) {
      _expenseChange = ((currentExpense - prevExpense) / prevExpense) * 100;
    } else if (currentExpense != 0) {
      _expenseChange = 100.0;
    } else {
      _expenseChange = 0.0;
    }
  }

  Future<void> _loadCashBalanceData() async {
    try {
      final now = DateTime.now();

      // Use global range selection: m3=90 days, m6=180 days, m12=365 days
      final int days = _range == _AnalyticsRange.m3
          ? 90
          : _range == _AnalyticsRange.m6
              ? 180
              : 365;

      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
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

      // Fetch all transactions BEFORE the chart period to compute pre-period balance
      final allTransactionsBeforeStart =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        DateTime(2000, 1, 1), // far in the past
        startDateNormalized.subtract(const Duration(days: 1)),
      );

      double prePeriodNet = 0.0;
      for (final tx in allTransactionsBeforeStart) {
        prePeriodNet += tx.type == 'income' ? tx.amount : -tx.amount;
      }

      // The baseline for the chart is: starting balance + all transactions before chart period
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

      // Track which day indices have transactions
      final Set<int> txDayIndices = {};

      for (final tx in transactions) {
        final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        if (!dailyNetChanges.containsKey(key)) continue;

        // Calculate day index for this transaction
        final dayIndex = d.difference(startDateNormalized).inDays;
        if (dayIndex >= 0 && dayIndex < days) {
          txDayIndices.add(dayIndex);
        }

        dailyNetChanges[key] =
            (dailyNetChanges[key] ?? 0) +
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

      _balanceData = series;
      _transactionDayIndices = txDayIndices;
    } catch (_) {
      _balanceData = [];
      _transactionDayIndices = {};
    }
  }

  /// Returns (latestBalance, meaningfulPointCount) from insight balance data.
  /// Uses fixed 90-day window independent of chart range.
  ({double? balance, int count}) _getInsightCashBalanceData() {
    if (_insightBalanceData.isEmpty) return (balance: null, count: 0);

    int meaningfulCount = 0;
    double? latestBalance;

    for (int i = _insightBalanceData.length - 1; i >= 0; i--) {
      final balance = (_insightBalanceData[i]['balance'] as num?)?.toDouble();
      if (balance != null && !balance.isNaN) {
        meaningfulCount++;
        latestBalance ??= balance;
      }
    }

    // Require at least 2 meaningful points
    if (meaningfulCount < 2) {
      return (balance: null, count: meaningfulCount);
    }

    return (balance: latestBalance, count: meaningfulCount);
  }

  /// Refreshes the current insight based on cash balance data.
  Future<void> _refreshInsight() async {
    // Use insight-specific data (fixed windows, independent of chart range)
    final cashInterp = _getInsightCashBalanceTrendInterpretation(context);
    final cashStatus = cashInterp?.status;

    // Get latest cash balance with meaningful point count (from insight data)
    final cashData = _getInsightCashBalanceData();

    // Pick top insight
    const engine = InsightEngine();
    final insight = engine.pickTopInsight(
      cashStatus: cashStatus,
      latestCashBalance: cashData.balance,
      meaningfulCashPointCount: cashData.count,
      avgMonthlyExpense: _avgMonthlyExpenseForRunway,
      recentExpenseTotal: _recentExpenseTotal,
      priorExpenseTotal: _priorExpenseTotal,
      incomeType: _incomeType,
      recentIncomeTotal: _recentIncomeTotal,
      priorIncomeTotal: _priorIncomeTotal,
    );

    if (insight == null) {
      _currentInsight = null;
      _currentInsightDismissedUntil = null;
      return;
    }

    // Check if dismissed
    final dismissedUntil = await _insightStore.getDismissedUntil(insight.id);
    final now = DateTime.now();

    if (dismissedUntil != null && dismissedUntil.isAfter(now)) {
      _currentInsight = insight;
      _currentInsightDismissedUntil = dismissedUntil;
    } else {
      _currentInsight = insight;
      _currentInsightDismissedUntil = null;
    }
  }

  /// Returns the dismiss duration in days for a given insight.
  int _getDismissDurationDays(InsightId id) {
    switch (id) {
      case InsightId.lowCashBuffer:
        return 7;
      case InsightId.lowCashRunway:
        return 7;
      case InsightId.missingIncome:
        return 14;
      case InsightId.expenseSpike:
        return 14;
    }
  }

  /// Returns the localized title for the given insight.
  String _getInsightTitle(AppLocalizations l10n, Insight insight) {
    switch (insight.id) {
      case InsightId.lowCashBuffer:
        return l10n.insightLowCashTitle;
      case InsightId.lowCashRunway:
        return l10n.insightLowRunwayTitle;
      case InsightId.missingIncome:
        return l10n.insightMissingIncomeTitle;
      case InsightId.expenseSpike:
        return l10n.insightExpenseSpikeTitle;
    }
  }

  /// Returns the localized body for the given insight.
  String _getInsightBody(AppLocalizations l10n, Insight insight) {
    switch (insight.id) {
      case InsightId.lowCashBuffer:
        return insight.severity == InsightSeverity.risk
            ? l10n.insightLowCashBodyRisk
            : l10n.insightLowCashBodyWatch;
      case InsightId.lowCashRunway:
        // Compute runway days for display (use floor for conservative messaging)
        // Use insight-specific data (fixed 90-day window) for consistency with evaluation
        final cashData = _getInsightCashBalanceData();
        final avgExpense = _avgMonthlyExpenseForRunway ?? 0.0;
        int runwayDays = 0;
        if (cashData.balance != null && avgExpense > 0) {
          final avgDailyBurn = avgExpense / 30.0;
          runwayDays = (cashData.balance! / avgDailyBurn).floor();
        }
        return insight.severity == InsightSeverity.risk
            ? l10n.insightLowRunwayBodyRisk(runwayDays)
            : l10n.insightLowRunwayBodyWatch(runwayDays);
      case InsightId.missingIncome:
        // Format month labels for display
        final incomeRecentMonth = _missingIncomeRecentMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_missingIncomeRecentMonthStart!)
            : '';
        final incomePriorMonth = _missingIncomePriorMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_missingIncomePriorMonthStart!)
            : '';
        return insight.severity == InsightSeverity.risk
            ? l10n.insightMissingIncomeBodyRisk(incomePriorMonth, incomeRecentMonth)
            : l10n.insightMissingIncomeBodyWatch(incomeRecentMonth);
      case InsightId.expenseSpike:
        // Format month labels for display
        final recentMonth = _expenseSpikeRecentMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_expenseSpikeRecentMonthStart!)
            : '';
        final priorMonth = _expenseSpikePriorMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_expenseSpikePriorMonthStart!)
            : '';
        return l10n.insightExpenseSpikeBody(recentMonth, priorMonth);
    }
  }

  /// Returns explainability text for Expense Spike insight only.
  String? _getExpenseSpikeExplainability(BuildContext context) {
    if (_currentInsight?.id != InsightId.expenseSpike) return null;
    if (_recentExpenseTotal == 0 && _priorExpenseTotal == 0) return null;

    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
    );

    final recentMonth = _expenseSpikeRecentMonthStart != null
        ? DateFormat.MMM(_dateLocale).format(_expenseSpikeRecentMonthStart!)
        : '';
    final priorMonth = _expenseSpikePriorMonthStart != null
        ? DateFormat.MMM(_dateLocale).format(_expenseSpikePriorMonthStart!)
        : '';

    final recentStr = currency.format(_recentExpenseTotal);
    final priorStr = currency.format(_priorExpenseTotal);

    final abs = _expenseSpikeAbsoluteIncrease;
    final absSign = abs >= 0 ? '+' : '-';
    final absStr = '$absSign${currency.format(abs.abs())}';

    final pct = _expenseSpikePercentIncrease;
    final pctStr = pct.isNaN ? '0' : pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0);
    final pctSign = pct >= 0 ? '+' : '-';
    final pctSigned = '$pctSign$pctStr';

    return l10n.insightExpenseSpikeWhy(
      recentMonth,
      recentStr,
      priorMonth,
      priorStr,
      absStr,
      pctSigned,
    );
  }

  /// Returns explainability text for Missing Income insight only.
  String? _getMissingIncomeExplainability(BuildContext context) {
    if (_currentInsight?.id != InsightId.missingIncome) return null;

    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
    );

    final recentMonth = _missingIncomeRecentMonthStart != null
        ? DateFormat.MMM(_dateLocale).format(_missingIncomeRecentMonthStart!)
        : '';
    final priorMonth = _missingIncomePriorMonthStart != null
        ? DateFormat.MMM(_dateLocale).format(_missingIncomePriorMonthStart!)
        : '';

    final recentStr = currency.format(_recentIncomeTotal);
    final priorStr = currency.format(_priorIncomeTotal);

    return l10n.insightMissingIncomeWhy(recentMonth, recentStr, priorMonth, priorStr);
  }

  /// Returns explainability text for Low Cash Runway insight only.
  String? _getLowCashRunwayExplainability(BuildContext context) {
    if (_currentInsight?.id != InsightId.lowCashRunway) return null;

    // Use insight-specific data (fixed 90-day window) - same as insight evaluation
    final cashData = _getInsightCashBalanceData();
    final balance = cashData.balance;
    final avg = _avgMonthlyExpenseForRunway;

    // Guard: return null if we can't compute meaningful values
    if (balance == null || balance.isNaN) return null;
    if (balance <= 0) return null;
    if (avg == null || avg.isNaN || avg <= 0) return null;

    // Match exact calculation from _getInsightBody
    final avgDailyBurn = avg / 30.0;
    final runwayDays = (balance / avgDailyBurn).floor();

    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
    );

    return l10n.insightLowCashRunwayWhy(
      currency.format(balance),
      currency.format(avg),
      runwayDays.toString(),
    );
  }

  /// Returns explainability text for Low Cash Buffer insight only.
  String? _getLowCashBufferExplainability(BuildContext context) {
    if (_currentInsight?.id != InsightId.lowCashBuffer) return null;

    // Use insight-specific data (fixed 90-day window)
    final cashData = _getInsightCashBalanceData();
    final balance = cashData.balance;

    if (balance == null || balance.isNaN) return null;

    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
    );

    // Determine trend suffix from insight interpretation
    String trendSuffix = '';
    final interp = _getInsightCashBalanceTrendInterpretation(context);
    if (interp != null &&
        (interp.status == InterpretationStatus.watch ||
         interp.status == InterpretationStatus.risk)) {
      // Use localized trend suffix
      trendSuffix = l10n.localeName == 'pt'
          ? ' e uma tendência descendente'
          : ' and a downward trend';
    }

    return l10n.insightLowCashBufferWhy(
      currency.format(balance),
      trendSuffix,
    );
  }

  /// Returns detail lines for v2 explainability.
  List<String>? _getInsightDetails(BuildContext context) {
    final insight = _currentInsight;
    if (insight == null) return null;

    final l10n = AppLocalizations.of(context)!;

    switch (insight.id) {
      case InsightId.expenseSpike:
        final recentMonth = _expenseSpikeRecentMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_expenseSpikeRecentMonthStart!)
            : '';
        final priorMonth = _expenseSpikePriorMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_expenseSpikePriorMonthStart!)
            : '';
        if (recentMonth.isEmpty || priorMonth.isEmpty) return null;

        // Case 1: More transactions in recent month
        if (_expenseSpikeRecentTxCount > _expenseSpikePriorTxCount) {
          return [
            l10n.insightDetailExpenseSpikeCause(
              recentMonth,
              _expenseSpikeRecentTxCount,
              priorMonth,
              _expenseSpikePriorTxCount,
            ),
          ];
        }

        // Case 2: Higher average spend (both have transactions)
        if (_expenseSpikeRecentTxCount > 0 && _expenseSpikePriorTxCount > 0) {
          final currency = NumberFormat.currency(
            locale: _currencyLocale,
            symbol: _currencySymbol,
          );
          final recentAvg = _recentExpenseTotal / _expenseSpikeRecentTxCount;
          final priorAvg = _priorExpenseTotal / _expenseSpikePriorTxCount;
          return [
            l10n.insightDetailExpenseSpikeAvgCause(
              recentMonth,
              currency.format(recentAvg),
              priorMonth,
              currency.format(priorAvg),
            ),
          ];
        }

        // Case 3: Can't determine cause
        return null;

      case InsightId.missingIncome:
        // Only show when there were prior transactions (causal: had income, now none)
        if (_missingIncomePriorTxCount == 0) return null;
        final recentMonth = _missingIncomeRecentMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_missingIncomeRecentMonthStart!)
            : '';
        final priorMonth = _missingIncomePriorMonthStart != null
            ? DateFormat.MMM(_dateLocale).format(_missingIncomePriorMonthStart!)
            : '';
        if (recentMonth.isEmpty || priorMonth.isEmpty) return null;
        return [
          l10n.insightDetailMissingIncomeCause(
            recentMonth,
            _missingIncomePriorTxCount,
            priorMonth,
          ),
        ];

      case InsightId.lowCashRunway:
        if (_lowCashRunwayMonthsUsed == null) return null;
        return [
          l10n.insightDetailRunwayMonthsUsed(_lowCashRunwayMonthsUsed!),
        ];

      case InsightId.lowCashBuffer:
        if (!_lowCashBufferHasDownTrend) return null;
        final streak = _lowCashBufferDownTrendStreakDays;
        if (streak == null || streak == 0) return null;
        return [
          l10n.insightDetailDowntrendStreak(streak),
        ];
    }
  }

  List<Map<String, dynamic>> _buildIncomeExpensesMonthlyData({
    required List<TransactionRecord> transactions,
    required DateTime startMonth,
    required int months,
  }) {
    final result = <Map<String, dynamic>>[];

    for (var i = 0; i < months; i++) {
      final monthStart = DateTime(startMonth.year, startMonth.month + i, 1);
      final nextMonthStart =
          DateTime(startMonth.year, startMonth.month + i + 1, 1);

      double income = 0;
      double expenses = 0;

      for (final t in transactions) {
        final d = t.date;
        final inMonth = !d.isBefore(monthStart) && d.isBefore(nextMonthStart);
        if (!inMonth) continue;

        if (t.type == 'income') {
          income += t.amount;
        } else if (t.type == 'expense') {
          expenses += t.amount;
        }
      }

      final m = DateFormat('MMM', _dateLocale).format(monthStart);
      final y = DateFormat('yy', _dateLocale).format(monthStart);
      final monthLabel = '$m$y';

      result.add({
        'month': monthLabel,
        'income': income,
        'expenses': expenses,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> _buildProfitMonthlyData({
    required List<Map<String, dynamic>> incomeExpensesMonthlyData,
  }) {
    return incomeExpensesMonthlyData.map((m) {
      final income = (m['income'] as num).toDouble();
      final expenses = (m['expenses'] as num).toDouble();
      return {
        'month': m['month'],
        'profit': income - expenses,
      };
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> _buildCategoryBreakdownData({
    required List<TransactionRecord> transactions,
    required String type, // 'income' or 'expense'
  }) {
    final totalsByCategory = <String, double>{};

    for (final t in transactions) {
      if (t.type != type) continue;

      totalsByCategory.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total for percentage
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    // Top 3 categories + Others (if remaining)
    final top3 = entries.take(3).toList(growable: false);
    final remaining = entries.skip(3);

    double othersTotal = 0;
    for (final e in remaining) {
      othersTotal += e.value;
    }

    final result = <Map<String, dynamic>>[];

    for (final e in top3) {
      final category = TransactionCategory.fromDbValue(e.key);
      result.add({
        'category': category, // Store category for localization at display time
        'iconName': category?.iconName ?? 'category',
        'amount': e.value,
        'percentage': total > 0 ? (e.value / total) * 100 : 0.0,
        'isOthers': false,
      });
    }

    // Add "Others" card only if there are more categories beyond top 3
    if (othersTotal > 0) {
      result.add({
        'category': null, // null indicates "Others" - will be localized at display time
        'iconName': 'more_horiz',
        'amount': othersTotal,
        'percentage': total > 0 ? (othersTotal / total) * 100 : 0.0,
        'isOthers': true,
      });
    }

    return result;
  }

  /// Builds the FULL category list without truncation (for "View all" bottom sheet).
  List<Map<String, dynamic>> _buildFullCategoryList({
    required List<TransactionRecord> transactions,
    required String type,
  }) {
    final totalsByCategory = <String, double>{};

    for (final t in transactions) {
      if (t.type != type) continue;

      totalsByCategory.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return entries.map((e) {
      final category = TransactionCategory.fromDbValue(e.key);
      return {
        'category': category, // Store category for localization at display time
        'iconName': category?.iconName ?? 'category',
        'amount': e.value,
        'percentage': total > 0 ? (e.value / total) * 100 : 0.0,
      };
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              l10n.noDataYet,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.addTransactionsToSeeTrends,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a consistent card container with frosted glass styling.
  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required Widget child,
    double? height,
    Widget? badge,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: Container(
          height: height,
          constraints: height == null
              ? BoxConstraints(minHeight: 28.h, maxHeight: 38.h)
              : null,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass80Light,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
            border: Border.all(
              color: AppColors.borderGlass60Light,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChartCardHeader(
                title: title,
                badge: badge,
                subtitle: subtitle,
              ),
              SizedBox(height: 2.h),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns localized interpretation for Income vs Expenses chart.
  /// Uses latest month with meaningful data (income or expenses > 0).
  _IncomeVsExpensesInterpretationData? _getIncomeVsExpensesInterpretation(
      BuildContext context) {
    if (_incomeExpensesData.isEmpty) return null;

    // Find latest month with meaningful data (iterate from end)
    double income = 0.0;
    double expenses = 0.0;
    bool foundMeaningful = false;

    for (int i = _incomeExpensesData.length - 1; i >= 0; i--) {
      final monthData = _incomeExpensesData[i];
      final monthIncome = (monthData['income'] as num?)?.toDouble() ?? 0.0;
      final monthExpenses = (monthData['expenses'] as num?)?.toDouble() ?? 0.0;

      if (monthIncome != 0 || monthExpenses != 0) {
        income = monthIncome;
        expenses = monthExpenses;
        foundMeaningful = true;
        break;
      }
    }

    if (!foundMeaningful) return null;

    final l10n = AppLocalizations.of(context)!;

    const interpreter = IncomeVsExpensesInterpreter();
    final interpretation = interpreter.interpret(
      income: income,
      expenses: expenses,
    );

    // Map status to localized label and explanation
    switch (interpretation.status) {
      case InterpretationStatus.healthy:
        return _IncomeVsExpensesInterpretationData(
          status: InterpretationStatus.healthy,
          label: l10n.analyticsHealthy,
          explanation: l10n.analyticsIncomeVsExpensesHealthyExplanation,
        );
      case InterpretationStatus.watch:
        return _IncomeVsExpensesInterpretationData(
          status: InterpretationStatus.watch,
          label: l10n.analyticsWatch,
          explanation: l10n.analyticsIncomeVsExpensesWatchExplanation,
        );
      case InterpretationStatus.risk:
        return _IncomeVsExpensesInterpretationData(
          status: InterpretationStatus.risk,
          label: l10n.analyticsRisk,
          explanation: l10n.analyticsIncomeVsExpensesRiskExplanation,
        );
    }
  }

  /// Returns semantic background color for interpretation badge.
  Color _badgeBackground(InterpretationStatus status, ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    switch (status) {
      case InterpretationStatus.healthy:
        return isDark
            ? AppColors.emerald900.withValues(alpha: 0.30)
            : AppColors.emerald100;
      case InterpretationStatus.watch:
        return isDark
            ? AppColors.amber900.withValues(alpha: 0.30)
            : AppColors.amber100;
      case InterpretationStatus.risk:
        return isDark
            ? AppColors.rose900.withValues(alpha: 0.30)
            : AppColors.rose100;
    }
  }

  /// Returns semantic text color for interpretation badge.
  Color _badgeText(InterpretationStatus status, ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    switch (status) {
      case InterpretationStatus.healthy:
        return isDark ? AppColors.emerald400 : AppColors.emerald700;
      case InterpretationStatus.watch:
        return isDark ? AppColors.amber400 : AppColors.amber700;
      case InterpretationStatus.risk:
        return isDark ? AppColors.rose400 : AppColors.rose700;
    }
  }

  /// Builds a status badge for the Income vs Expenses chart.
  Widget? _buildIncomeVsExpensesBadge(
      BuildContext context, _IncomeVsExpensesInterpretationData? interp) {
    if (interp == null) return null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _badgeBackground(interp.status, colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        interp.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _badgeText(interp.status, colorScheme),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Returns localized interpretation for Cash Balance Trend chart.
  /// Returns null if data is insufficient or all zero.
  _CashBalanceTrendInterpretationData? _getCashBalanceTrendInterpretation(
      BuildContext context) {
    // Need at least 2 data points for meaningful analysis
    if (_balanceData.length < 2) return null;

    // Check if there's any non-zero balance
    bool hasMeaningfulData = false;
    for (final point in _balanceData) {
      final balance = (point['balance'] as num?)?.toDouble() ?? 0.0;
      if (balance != 0) {
        hasMeaningfulData = true;
        break;
      }
    }
    if (!hasMeaningfulData) return null;

    final l10n = AppLocalizations.of(context)!;

    const interpreter = CashBalanceTrendInterpreter();
    final interpretation = interpreter.interpret(balanceData: _balanceData);

    // Interpreter returns null if fewer than 2 meaningful points
    if (interpretation == null) return null;

    // Map status to localized label and explanation
    switch (interpretation.status) {
      case InterpretationStatus.healthy:
        return _CashBalanceTrendInterpretationData(
          status: InterpretationStatus.healthy,
          label: l10n.analyticsHealthy,
          explanation: l10n.analyticsCashBalanceHealthyExplanation,
        );
      case InterpretationStatus.watch:
        return _CashBalanceTrendInterpretationData(
          status: InterpretationStatus.watch,
          label: l10n.analyticsWatch,
          explanation: l10n.analyticsCashBalanceWatchExplanation,
        );
      case InterpretationStatus.risk:
        return _CashBalanceTrendInterpretationData(
          status: InterpretationStatus.risk,
          label: l10n.analyticsRisk,
          explanation: l10n.analyticsCashBalanceRiskExplanation,
        );
    }
  }

  /// Returns cash balance trend interpretation for insight evaluation.
  /// Uses fixed 90-day window independent of chart range.
  _CashBalanceTrendInterpretationData? _getInsightCashBalanceTrendInterpretation(
      BuildContext context) {
    if (_insightBalanceData.length < 2) return null;

    bool hasMeaningfulData = false;
    for (final point in _insightBalanceData) {
      final balance = (point['balance'] as num?)?.toDouble() ?? 0.0;
      if (balance != 0) {
        hasMeaningfulData = true;
        break;
      }
    }
    if (!hasMeaningfulData) return null;

    final l10n = AppLocalizations.of(context)!;

    const interpreter = CashBalanceTrendInterpreter();
    final interpretation = interpreter.interpret(balanceData: _insightBalanceData);

    if (interpretation == null) return null;

    switch (interpretation.status) {
      case InterpretationStatus.healthy:
        return _CashBalanceTrendInterpretationData(
          status: InterpretationStatus.healthy,
          label: l10n.analyticsHealthy,
          explanation: l10n.analyticsCashBalanceHealthyExplanation,
        );
      case InterpretationStatus.watch:
        return _CashBalanceTrendInterpretationData(
          status: InterpretationStatus.watch,
          label: l10n.analyticsWatch,
          explanation: l10n.analyticsCashBalanceWatchExplanation,
        );
      case InterpretationStatus.risk:
        return _CashBalanceTrendInterpretationData(
          status: InterpretationStatus.risk,
          label: l10n.analyticsRisk,
          explanation: l10n.analyticsCashBalanceRiskExplanation,
        );
    }
  }

  /// Builds a status badge for the Cash Balance Trend chart.
  Widget? _buildCashBalanceTrendBadge(
      BuildContext context, _CashBalanceTrendInterpretationData? interp) {
    if (interp == null) return null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _badgeBackground(interp.status, colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        interp.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _badgeText(interp.status, colorScheme),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Returns localized interpretation for Profit Trends chart.
  /// Returns null if data is insufficient or all zero.
  _ProfitTrendInterpretationData? _getProfitTrendInterpretation(
      BuildContext context) {
    if (_profitTrendsData.length < 2) return null;

    // Check for meaningful (non-zero) data
    bool hasMeaningfulData = false;
    for (final point in _profitTrendsData) {
      final profit = (point['profit'] as num?)?.toDouble();
      if (profit != null && !profit.isNaN && profit != 0) {
        hasMeaningfulData = true;
        break;
      }
    }
    if (!hasMeaningfulData) return null;

    final l10n = AppLocalizations.of(context)!;

    const interpreter = ProfitTrendInterpreter();
    final interpretation = interpreter.interpret(profitData: _profitTrendsData);

    if (interpretation == null) return null;

    switch (interpretation.status) {
      case InterpretationStatus.healthy:
        return _ProfitTrendInterpretationData(
          status: InterpretationStatus.healthy,
          label: l10n.analyticsHealthy,
          explanation: l10n.analyticsProfitHealthyExplanation,
        );
      case InterpretationStatus.watch:
        return _ProfitTrendInterpretationData(
          status: InterpretationStatus.watch,
          label: l10n.analyticsWatch,
          explanation: l10n.analyticsProfitWatchExplanation,
        );
      case InterpretationStatus.risk:
        return _ProfitTrendInterpretationData(
          status: InterpretationStatus.risk,
          label: l10n.analyticsRisk,
          explanation: l10n.analyticsProfitRiskExplanation,
        );
    }
  }

  /// Builds a status badge for the Profit Trends chart.
  Widget? _buildProfitTrendBadge(
      BuildContext context, _ProfitTrendInterpretationData? interp) {
    if (interp == null) return null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _badgeBackground(interp.status, colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        interp.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _badgeText(interp.status, colorScheme),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Returns localized interpretation for Expense Breakdown.
  _CategoryBreakdownInterpretationData? _getExpenseBreakdownInterpretation(
      BuildContext context) {
    if (_expenseCategoryData.isEmpty) return null;

    final l10n = AppLocalizations.of(context)!;
    const interpreter = CategoryBreakdownInterpreter();

    final interpretation =
        interpreter.interpret(categories: _expenseCategoryData);

    if (interpretation == null) return null;

    switch (interpretation.status) {
      case InterpretationStatus.healthy:
        return _CategoryBreakdownInterpretationData(
          status: interpretation.status,
          label: l10n.analyticsHealthy,
          explanation: l10n.analyticsExpenseBreakdownHealthy,
        );
      case InterpretationStatus.watch:
        return _CategoryBreakdownInterpretationData(
          status: interpretation.status,
          label: l10n.analyticsWatch,
          explanation: l10n.analyticsExpenseBreakdownWatch,
        );
      case InterpretationStatus.risk:
        return _CategoryBreakdownInterpretationData(
          status: interpretation.status,
          label: l10n.analyticsRisk,
          explanation: l10n.analyticsExpenseBreakdownRisk,
        );
    }
  }

  /// Returns localized interpretation for Income Sources.
  _CategoryBreakdownInterpretationData? _getIncomeBreakdownInterpretation(
      BuildContext context) {
    if (_incomeCategoryData.isEmpty) return null;

    final l10n = AppLocalizations.of(context)!;
    const interpreter = CategoryBreakdownInterpreter();

    final interpretation =
        interpreter.interpret(categories: _incomeCategoryData);

    if (interpretation == null) return null;

    switch (interpretation.status) {
      case InterpretationStatus.healthy:
        return _CategoryBreakdownInterpretationData(
          status: interpretation.status,
          label: l10n.analyticsHealthy,
          explanation: l10n.analyticsIncomeBreakdownHealthy,
        );
      case InterpretationStatus.watch:
        return _CategoryBreakdownInterpretationData(
          status: interpretation.status,
          label: l10n.analyticsWatch,
          explanation: l10n.analyticsIncomeBreakdownWatch,
        );
      case InterpretationStatus.risk:
        return _CategoryBreakdownInterpretationData(
          status: interpretation.status,
          label: l10n.analyticsRisk,
          explanation: l10n.analyticsIncomeBreakdownRisk,
        );
    }
  }

  /// Builds a status badge for category breakdown sections.
  Widget? _buildCategoryBreakdownBadge(
      BuildContext context, _CategoryBreakdownInterpretationData? interp) {
    if (interp == null) return null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _badgeBackground(interp.status, colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        interp.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _badgeText(interp.status, colorScheme),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Shows a bottom sheet with the full category breakdown list.
  void _showCategoryBreakdownSheet({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> fullData,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Category list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  itemCount: fullData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = fullData[index];
                    final category = item['category'] as TransactionCategory?;
                    // Localize the category name at display time
                    final label = category != null
                        ? getLocalizedCategoryLabel(ctx, category)
                        : '';
                    final amount = (item['amount'] as num).toDouble();
                    final percentage = (item['percentage'] as num).toDouble();
                    final iconName = item['iconName'] as String;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: iconName,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          // Category name and percentage
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount
                          Text(
                            IncoreNumberFormatter.formatMoney(
                              amount,
                              locale: _currencyLocale,
                              symbol: _currencySymbol,
                              currencyCode: _currencyCode,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  /// Builds a card container with category tile cards inside.
  Widget _buildCategoryTilesCard({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> data,
    required Color accentColor,
    required List<Map<String, dynamic>> fullData,
    required VoidCallback onViewAll,
    Widget? badge,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass80Light,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
            border: Border.all(
              color: AppColors.borderGlass60Light,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChartCardHeader(
                title: title,
                badge: badge,
                subtitle: subtitle,
              ),
              SizedBox(height: 2.h),
              if (data.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Text(
                    l10n.noDataYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Row(
                  children: data.map((item) {
                    final category = item['category'] as TransactionCategory?;
                    final isOthers = item['isOthers'] as bool? ?? false;
                    // Localize the category name at display time
                    final categoryName = isOthers
                        ? l10n.other
                        : (category != null
                            ? getLocalizedCategoryLabel(context, category)
                            : '');
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1.w),
                        child: CategoryTileCard(
                          categoryName: categoryName,
                          categoryIcon: item['iconName'] as String,
                          amount: (item['amount'] as num).toDouble(),
                          percentage: (item['percentage'] as num).toDouble(),
                          locale: _currencyLocale,
                          symbol: _currencySymbol,
                          currencyCode: _currencyCode,
                          accentColor: accentColor,
                          isOthersCard: isOthers,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // Only show "View all" when there are more categories than displayed
              if (fullData.length > 3) ...[
                SizedBox(height: 1.5.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.viewAll,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvasFrostedLight,
      appBar: null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? AppErrorWidget(
                      error: _loadError!,
                      displayMode: AppErrorDisplayMode.fullScreen,
                      onRetry: _handleRefresh,
                    )
                  : _hasNoTransactions
                      ? _buildEmptyState(context)
                      : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          0, // Cards own their horizontal margins
                          AppTheme.screenTopPadding,
                          0, // Cards own their horizontal margins
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Insight card (shown when insight is active and not dismissed)
                            if (_currentInsight != null &&
                                _currentInsightDismissedUntil == null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: InsightCard(
                                  severity: _currentInsight!.severity,
                                  title: _getInsightTitle(l10n, _currentInsight!),
                                  body: _getInsightBody(l10n, _currentInsight!),
                                  secondaryText: _getLowCashBufferExplainability(context)
                                      ?? _getExpenseSpikeExplainability(context)
                                      ?? _getMissingIncomeExplainability(context)
                                      ?? _getLowCashRunwayExplainability(context),
                                  details: _getInsightDetails(context),
                                  actionLabel: l10n.insightActionReviewExpenses,
                                  onAction: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/transactions-list',
                                    );
                                  },
                                  onDismiss: () async {
                                    final days = _getDismissDurationDays(
                                      _currentInsight!.id,
                                    );
                                    await _insightStore.dismissForDays(
                                      _currentInsight!.id,
                                      days,
                                    );
                                    setState(() {
                                      _currentInsightDismissedUntil =
                                          DateTime.now().add(
                                        Duration(days: days),
                                      );
                                    });
                                  },
                                  dismissTooltip: l10n.insightDismiss,
                                ),
                              ),

                            // Calm relief banner (after successful pause)
                            if (_showPressureRelief &&
                                !(_currentInsight != null &&
                                    _currentInsightDismissedUntil == null))
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: PressureReliefBanner(
                                  title: l10n.pressureReliefTitle,
                                  subtitle: l10n.pressureReliefSubtitlePaused(
                                      _pausedBillsCount),
                                  onDismiss: () => setState(
                                      () => _showPressureRelief = false),
                                ),
                              ),

                            // Safety buffer row + pressure point line
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: SafetyBufferSection(
                                snapshot: _safetyBufferSnapshot,
                                taxShield: _taxShieldSnapshot,
                                activeRecurringExpenses: _activeRecurringExpenses,
                                currencyLocale: _currencyLocale,
                                currencySymbol: _currencySymbol,
                                isInsightCardVisible: _currentInsight != null &&
                                    _currentInsightDismissedUntil == null,
                                onReviewBillsTap: () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.recurringExpenses);
                                },
                                // Tax reserve is now inline below, no tap needed
                                onTaxShieldTap: null,
                                onPressurePointActionsOpened: () {
                                  _localEventStore.log('pressure_point_opened');
                                },
                                onPressurePointVisibilityChanged: (visible) {
                                  if (_isPressurePointVisible != visible) {
                                    _isPressurePointVisible = visible;
                                    if (!visible && _checkResolvedAfterPause) {
                                      _checkResolvedAfterPause = false;
                                      _localEventStore
                                          .log('pressure_point_resolved');
                                    }
                                  }
                                },
                                onPauseExpenses: (expenseIds) async {
                                  final count = expenseIds.length;
                                  for (final id in expenseIds) {
                                    await _recurringExpensesRepository
                                        .deactivateRecurringExpense(id: id);
                                  }
                                  if (!mounted) return;
                                  _checkResolvedAfterPause = true;
                                  await _loadAnalyticsData();
                                  if (!mounted) return;
                                  await _localEventStore.log(
                                    'pressure_point_paused_bills',
                                    props: {'count': count},
                                  );
                                  _showRelief(pausedCount: count);
                                },
                              ),
                            ),

                            // Inline Tax Reserve cards
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildTaxReserveRow(),
                            ),

                            // Inline Recurring Expenses cards
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildRecurringExpensesRow(),
                            ),

                            const SizedBox(height: 24),

                            // ========================================
                            // Section 1: Overview
                            // ========================================
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.overview,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.slate500,
                                            ),
                                      ),
                                      SegmentedButton<_AnalyticsRange>(
                                        segments: [
                                          ButtonSegment(
                                            value: _AnalyticsRange.m3,
                                            label: Text(l10n.threeMonths),
                                          ),
                                          ButtonSegment(
                                            value: _AnalyticsRange.m6,
                                            label: Text(l10n.sixMonths),
                                          ),
                                          ButtonSegment(
                                            value: _AnalyticsRange.m12,
                                            label: Text(l10n.twelveMonths),
                                          ),
                                        ],
                                        selected: {_range},
                                        showSelectedIcon: false,
                                        onSelectionChanged: (value) {
                                          setState(() {
                                            _range = value.first;
                                          });
                                          _loadAnalyticsData();
                                        },
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return AppColors.blue600;
                                            }
                                            return Colors.transparent;
                                          }),
                                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return Colors.white;
                                            }
                                            return AppColors.slate500;
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.appliesToChartsBelow,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Income vs Expenses chart
                            if (_incomeExpensesData.isEmpty)
                              Text(l10n.notEnoughData),
                            if (_incomeExpensesData.isNotEmpty) ...[
                              () {
                                final interp =
                                    _getIncomeVsExpensesInterpretation(context);
                                return _buildChartCard(
                                  context: context,
                                  title: l10n.incomeVsExpenses,
                                  badge:
                                      _buildIncomeVsExpensesBadge(context, interp),
                                  subtitle: interp?.explanation,
                                  child: IncomeExpensesChartWidget(
                                    chartData: _incomeExpensesData,
                                    locale: _currencyLocale,
                                    symbol: _currencySymbol,
                                    currencyCode: _currencyCode,
                                  ),
                                );
                              }(),
                            ],
                            const SizedBox(height: 16),

                            // Month-over-month comparison card
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ComparisonMetricsCard(
                                incomeChange: _incomeChange,
                                expenseChange: _expenseChange,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ========================================
                            // Section 2: Breakdown
                            // ========================================
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                l10n.breakdown,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate500,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Income sources card with tiles
                            () {
                              final interp =
                                  _getIncomeBreakdownInterpretation(context);
                              return _buildCategoryTilesCard(
                                context: context,
                                title: l10n.incomeSources,
                                data: _incomeCategoryData,
                                accentColor: AppColors.income,
                                fullData: _fullIncomeCategoryData,
                                onViewAll: () => _showCategoryBreakdownSheet(
                                  context: context,
                                  title: l10n.incomeSources,
                                  fullData: _fullIncomeCategoryData,
                                  accentColor: AppColors.income,
                                ),
                                badge: _buildCategoryBreakdownBadge(
                                    context, interp),
                                subtitle: interp?.explanation,
                              );
                            }(),
                            const SizedBox(height: 16),

                            // Expense breakdown card with tiles
                            () {
                              final interp =
                                  _getExpenseBreakdownInterpretation(context);
                              return _buildCategoryTilesCard(
                                context: context,
                                title: l10n.expenseBreakdown,
                                data: _expenseCategoryData,
                                accentColor: AppColors.expense,
                                fullData: _fullExpenseCategoryData,
                                onViewAll: () => _showCategoryBreakdownSheet(
                                  context: context,
                                  title: l10n.expenseBreakdown,
                                  fullData: _fullExpenseCategoryData,
                                  accentColor: AppColors.expense,
                                ),
                                badge: _buildCategoryBreakdownBadge(
                                    context, interp),
                                subtitle: interp?.explanation,
                              );
                            }(),
                            const SizedBox(height: 24),

                            // ========================================
                            // Section 3: Trends
                            // ========================================
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                l10n.trends,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate500,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Cash Balance chart
                            if (_balanceData.isNotEmpty)
                              () {
                                final interp =
                                    _getCashBalanceTrendInterpretation(context);
                                return _buildChartCard(
                                  context: context,
                                  title: l10n.cashBalanceTrend,
                                  badge:
                                      _buildCashBalanceTrendBadge(context, interp),
                                  subtitle: interp?.explanation,
                                  child: CashBalanceChart(
                                    balanceData: _balanceData,
                                    locale: _currencyLocale,
                                    symbol: _currencySymbol,
                                    currencyCode: _currencyCode,
                                    transactionIndices: _transactionDayIndices,
                                  ),
                                );
                              }(),
                            const SizedBox(height: 16),

                            // Profit trends chart
                            if (_profitTrendsData.isEmpty)
                              Text(l10n.notEnoughData),
                            if (_profitTrendsData.isNotEmpty)
                              () {
                                final interp =
                                    _getProfitTrendInterpretation(context);
                                return _buildChartCard(
                                  context: context,
                                  title: l10n.profitTrends,
                                  badge: _buildProfitTrendBadge(context, interp),
                                  subtitle: interp?.explanation,
                                  child: ProfitTrendsChartWidget(
                                    trendData: _profitTrendsData,
                                    locale: _currencyLocale,
                                    symbol: _currencySymbol,
                                    currencyCode: _currencyCode,
                                  ),
                                );
                              }(),

                            SizedBox(height: kBottomNavClearance),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.analytics,
        onItemSelected: (_) {},
        onAddTransaction: null,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadAnalyticsData();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Tax Reserve Inline Cards
  // ══════════════════════════════════════════════════════════════════════════

  /// Shared frosted card container for tax reserve cards
  Widget _buildFrostedCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass80Light,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
            border: Border.all(color: AppColors.borderGlass60Light, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Tax reserve cards displayed side by side with equal height
  Widget _buildTaxReserveRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildTaxReserveCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildTaxReserveHelperCard()),
        ],
      ),
    );
  }

  /// Tax reserve card with slider
  Widget _buildTaxReserveCard() {
    final theme = Theme.of(context);
    final percentInt = (_taxShieldPercent * 100).round();
    final reservedAmount = _taxShieldSnapshot?.taxShieldReserved ?? 0.0;
    final currency = NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
    );

    return _buildFrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax reserve',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentInt%',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currency.format(reservedAmount)} set aside',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 16),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.blue600,
              inactiveTrackColor: AppColors.slate400.withValues(alpha: 0.25),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 2,
                pressedElevation: 4,
              ),
              overlayColor: AppColors.blue600.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: _taxShieldPercent,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _taxShieldPercent = value;
                });
              },
              onChangeEnd: (value) async {
                // Persist and reload only when user finishes sliding
                await _taxShieldSettingsStore.setTaxShieldPercent(value);
                if (!mounted) return;
                await _loadAnalyticsData();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Helper card with dynamic title and body text
  Widget _buildTaxReserveHelperCard() {
    final theme = Theme.of(context);
    final helper = _getTaxReserveHelper();

    return _buildFrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helper.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.blue600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic helper title and body based on tax reserve percentage
  ({String title, String body}) _getTaxReserveHelper() {
    final percentInt = (_taxShieldPercent * 100).round();

    if (percentInt == 0) {
      return (
        title: 'No tax reserve',
        body: 'Your safety buffer assumes all income is spendable. '
            'If you pay taxes later, your buffer may look larger than what you can actually use.',
      );
    }

    if (percentInt <= 14) {
      return (
        title: 'Small reserve',
        body: 'A small reserve makes your safety buffer slightly more conservative. '
            'Consider increasing it if you regularly owe taxes.',
      );
    }

    if (percentInt <= 34) {
      return (
        title: 'Balanced',
        body: 'This amount is excluded from spendable cash. '
            'Your safety buffer is more realistic and safer.',
      );
    }

    return (
      title: 'High reserve',
      body: 'You are setting aside a large share of income. '
          'This increases safety but can make your spendable cash feel tighter.',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Recurring Expenses Inline Cards
  // ══════════════════════════════════════════════════════════════════════════

  /// Recurring expenses cards with responsive layout (wide: Row, narrow: Column)
  Widget _buildRecurringExpensesRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 400;

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildRecurringExpensesCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildRecurringExpensesHelperCard()),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildRecurringExpensesCard(),
            const SizedBox(height: 12),
            _buildRecurringExpensesHelperCard(),
          ],
        );
      },
    );
  }

  /// Recurring expenses card showing total monthly amount
  Widget _buildRecurringExpensesCard() {
    final theme = Theme.of(context);
    final total = _activeRecurringExpenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount.abs(),
    );
    final count = _activeRecurringExpenses.length;
    final currency = NumberFormat.currency(
      locale: _currencyLocale,
      symbol: _currencySymbol,
    );

    return _buildFrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly recurring',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(total),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fixed monthly expenses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate500,
            ),
          ),
          Text(
            '$count active items',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic helper based on recurring vs income ratio
  ({String title, String body}) _getRecurringExpensesHelper() {
    final total = _activeRecurringExpenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount.abs(),
    );

    // Get latest month's income from _incomeExpensesData
    double latestIncome = 0.0;
    if (_incomeExpensesData.isNotEmpty) {
      for (int i = _incomeExpensesData.length - 1; i >= 0; i--) {
        final income =
            (_incomeExpensesData[i]['income'] as num?)?.toDouble() ?? 0.0;
        if (income > 0) {
          latestIncome = income;
          break;
        }
      }
    }

    if (total == 0) {
      return (
        title: 'No fixed costs',
        body: 'You have no recurring expenses tracked. '
            'This gives you maximum flexibility month to month.',
      );
    }

    if (latestIncome > 0 && total / latestIncome > 0.6) {
      return (
        title: 'High fixed load',
        body: 'A large part of your income goes to fixed costs. '
            'This reduces flexibility in low-income months.',
      );
    }

    if (latestIncome > 0 && total / latestIncome > 0.4) {
      return (
        title: 'Moderate baseline',
        body: 'Your fixed costs form a significant baseline. '
            'Keep an eye on adding new recurring commitments.',
      );
    }

    return (
      title: 'Predictable base',
      body: 'These expenses form your fixed monthly baseline. '
          'They are always accounted for in your safety buffer.',
    );
  }

  /// Helper card with dynamic title and body text
  Widget _buildRecurringExpensesHelperCard() {
    final theme = Theme.of(context);
    final helper = _getRecurringExpensesHelper();

    return _buildFrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helper.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.blue600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
