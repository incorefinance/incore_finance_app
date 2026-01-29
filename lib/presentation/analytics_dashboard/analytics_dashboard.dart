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

      // Load cash balance data (30 days)
      await _loadCashBalanceData();

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

  /// Builds a consistent card container matching the CashBalanceChart style.
  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required Widget child,
    double? height,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      height: height,
      constraints: height == null
          ? BoxConstraints(minHeight: 28.h, maxHeight: 38.h)
          : null,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(child: child),
        ],
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
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
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
                              l10n.overview,
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
                              _buildChartCard(
                                context: context,
                                title: l10n.incomeVsExpenses,
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
                              l10n.breakdown,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Income sources card with tiles
                            _buildCategoryTilesCard(
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
                            ),
                            const SizedBox(height: 16),

                            // Expense breakdown card with tiles
                            _buildCategoryTilesCard(
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
                            ),
                            const SizedBox(height: 24),

                            // ========================================
                            // Section 3: Trends
                            // ========================================
                            Text(
                              l10n.trends,
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
                              _buildChartCard(
                                context: context,
                                title: l10n.cashBalanceTrend,
                                child: CashBalanceChart(
                                  balanceData: _balanceData,
                                  locale: _currencyLocale,
                                  symbol: _currencySymbol,
                                  currencyCode: _currencyCode,
                                  transactionIndices: _transactionDayIndices,
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Profit trends chart
                            if (_profitTrendsData.isEmpty)
                              Text(l10n.notEnoughData),
                            if (_profitTrendsData.isNotEmpty)
                              _buildChartCard(
                                context: context,
                                title: l10n.profitTrends,
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
