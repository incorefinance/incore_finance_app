import 'package:flutter/material.dart';
import 'package:incore_finance/core/navigation/route_observer.dart';
import 'package:incore_finance/widgets/custom_bottom_bar.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import './widgets/income_expenses_chart_widget.dart';
import './widgets/horizontal_category_breakdown_widget.dart';
import './widgets/profit_trends_chart_widget.dart';
import './widgets/cash_balance_chart.dart';
import './widgets/comparison_metrics_card.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_financial_baseline_repository.dart';
import 'package:incore_finance/models/transaction_category.dart';
import 'package:incore_finance/core/state/transactions_change_notifier.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

String _dateLocale = 'en_US';

enum _AnalyticsRange { m3, m6, m12 }

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
  String? _loadError;
  bool _hasNoTransactions = false;

  List<Map<String, dynamic>> _incomeExpensesData = [];
  List<Map<String, dynamic>> _profitTrendsData = [];
  List<Map<String, dynamic>> _incomeCategoryData = [];
  List<Map<String, dynamic>> _expenseCategoryData = [];
  List<Map<String, dynamic>> _balanceData = [];

  // Month-over-month change data
  double _incomeChange = 0.0;
  double _expenseChange = 0.0;

  _AnalyticsRange _range = _AnalyticsRange.m3;

  final UserSettingsService _settingsService = UserSettingsService();

  // Currency settings
  String _currencyLocale = 'pt_PT';
  String _currencySymbol = '€';
  String _currencyCode = 'EUR';

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

      _expenseCategoryData = _buildCategoryBreakdownData(
        transactions: transactions,
        type: 'expense',
      );

      // Calculate month-over-month changes
      _calculateMonthOverMonthChanges(transactions, now);

      // Load cash balance data (30 days)
      await _loadCashBalanceData();

      setState(() {
        _isLoading = false;
        _hasNoTransactions = !hasData;
      });
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('=== ANALYTICS LOAD ERROR ===');
      // ignore: avoid_print
      print('Error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load analytics. Please try again.';
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

      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDate = endDate.subtract(const Duration(days: 29));
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

      for (int i = 0; i < 30; i++) {
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

        dailyNetChanges[key] =
            (dailyNetChanges[key] ?? 0) +
                (tx.type == 'income' ? tx.amount : -tx.amount);
      }

      final List<Map<String, dynamic>> series = [];
      double runningBalance = chartBaseline;

      // ignore: avoid_print
      print('=== CASH BALANCE CHART DEBUG ===');
      // ignore: avoid_print
      print('Starting balance: $startingBalance');
      // ignore: avoid_print
      print('Pre-period net: $prePeriodNet');
      // ignore: avoid_print
      print('Chart baseline: $chartBaseline');
      // ignore: avoid_print
      print('Transactions in period: ${transactions.length}');

      for (int i = 0; i < 30; i++) {
        final date = startDateNormalized.add(Duration(days: i));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        runningBalance += dailyNetChanges[key] ?? 0;
        series.add({'date': date, 'balance': runningBalance});
      }

      // ignore: avoid_print
      if (series.isNotEmpty) {
        // ignore: avoid_print
        print('First 3 series points:');
        for (int i = 0; i < 3 && i < series.length; i++) {
          // ignore: avoid_print
          print('  [$i] date: ${series[i]['date']}, balance: ${series[i]['balance']}');
        }
      }

      _balanceData = series;
    } catch (_) {
      _balanceData = [];
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

    // Top 5 + Other
    final top = entries.take(5).toList(growable: false);
    final rest = entries.skip(5);

    double otherTotal = 0;
    for (final e in rest) {
      otherTotal += e.value;
    }

    final result = <Map<String, dynamic>>[];

    for (final e in top) {
      final category = TransactionCategory.fromDbValue(e.key);
      result.add({
        'label': category?.label ?? e.key,
        'amount': e.value,
      });
    }

    if (otherTotal > 0) {
      result.add({
        'label': 'Other',
        'amount': otherTotal,
      });
    }

    return result;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              'No data yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Add a few transactions to see trends and breakdowns',
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

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            SizedBox(height: 3.h),
            Text(
              _loadError ?? 'Something went wrong',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? _buildErrorState(context)
                  : _hasNoTransactions
                      ? _buildEmptyState(context)
                      : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppTheme.screenHorizontalPadding,
                          AppTheme.screenTopPadding,
                          AppTheme.screenHorizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Range selector
                            Align(
                              alignment: Alignment.centerRight,
                              child: SegmentedButton<_AnalyticsRange>(
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
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ========================================
                            // Section 1: Overview
                            // ========================================
                            Text(
                              'Overview',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Income vs Expenses chart
                            if (_incomeExpensesData.isEmpty)
                              Text(l10n.notEnoughData),
                            if (_incomeExpensesData.isNotEmpty)
                              SizedBox(
                                height: 30.h,
                                child: IncomeExpensesChartWidget(
                                  chartData: _incomeExpensesData,
                                  locale: _currencyLocale,
                                  symbol: _currencySymbol,
                                  currencyCode: _currencyCode,
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Month-over-month comparison card
                            ComparisonMetricsCard(
                              incomeChange: _incomeChange,
                              expenseChange: _expenseChange,
                            ),
                            const SizedBox(height: 24),

                            // ========================================
                            // Section 2: Breakdown
                            // ========================================
                            Text(
                              'Breakdown',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Income sources
                            Text(
                              l10n.incomeSources,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            HorizontalCategoryBreakdownWidget(
                              data: _incomeCategoryData,
                              locale: _currencyLocale,
                              symbol: _currencySymbol,
                              currencyCode: _currencyCode,
                              accentColor: AppColors.income,
                            ),
                            const SizedBox(height: 24),

                            // Expense breakdown
                            Text(
                              l10n.expenseBreakdown,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            HorizontalCategoryBreakdownWidget(
                              data: _expenseCategoryData,
                              locale: _currencyLocale,
                              symbol: _currencySymbol,
                              currencyCode: _currencyCode,
                              accentColor: AppColors.expense,
                            ),
                            const SizedBox(height: 24),

                            // ========================================
                            // Section 3: Trends
                            // ========================================
                            Text(
                              'Trends',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Cash Balance chart
                            if (_balanceData.isNotEmpty)
                              CashBalanceChart(
                                balanceData: _balanceData,
                                locale: _currencyLocale,
                                symbol: _currencySymbol,
                                currencyCode: _currencyCode,
                              ),
                            const SizedBox(height: 16),

                            // Profit trends chart
                            if (_profitTrendsData.isEmpty)
                              Text(l10n.notEnoughData),
                            if (_profitTrendsData.isNotEmpty)
                              SizedBox(
                                height: 30.h,
                                child: ProfitTrendsChartWidget(
                                  trendData: _profitTrendsData,
                                  locale: _currencyLocale,
                                  symbol: _currencySymbol,
                                  currencyCode: _currencyCode,
                                ),
                              ),

                            SizedBox(height: 10.h),
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
}
