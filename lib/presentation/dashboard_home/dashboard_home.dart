import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_settings_service.dart';

import '../../core/app_export.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/cash_balance_chart.dart';
import './widgets/comparison_metrics_card.dart';
import './widgets/expense_category_card.dart';
import './widgets/monthly_profit_card.dart';

/// Dashboard Home Screen
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final TransactionsRepository _transactionsRepository =
      TransactionsRepository();
  final UserSettingsService _userSettingsService = UserSettingsService();

  double _monthlyProfit = 0.0;
  double _profitPercentageChange = 0.0;
  bool _isProfit = true;

  bool _isLoadingDashboard = true;
  String? _dashboardError;

  UserCurrencySettings _currencySettings = const UserCurrencySettings(
    currencyCode: 'EUR',
    symbol: '€',
    locale: 'pt_PT',
  );

  List<Map<String, dynamic>> _topExpenses = [];
  bool _isLoadingTopExpenses = true;

  List<Map<String, dynamic>> _balanceData = [];
  bool _isLoadingBalanceData = true;

  double _incomeChange = 0.0;
  double _expenseChange = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings().then((_) {
      _loadCashBalanceData();
      _loadMonthlyProfit();
      _loadTopExpenses();
    });
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      setState(() {
        _currencySettings = settings;
      });
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> _loadMonthlyProfit() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final now = DateTime.now();

      final currentMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);

      final currentMonthEnd =
          nextMonthStart.subtract(const Duration(milliseconds: 1));

      final List<TransactionRecord> currentTxs =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        currentMonthStart,
        currentMonthEnd,
      );

      double currentIncome = 0;
      double currentExpense = 0;

      for (final tx in currentTxs) {
        if (tx.type == 'income') {
          currentIncome += tx.amount;
        } else if (tx.type == 'expense') {
          currentExpense += tx.amount;
        }
      }

      final currentProfit = currentIncome - currentExpense;

      final prevMonthEnd = currentMonthStart.subtract(const Duration(days: 1));
      final prevMonthStart = DateTime(prevMonthEnd.year, prevMonthEnd.month, 1);

      final List<TransactionRecord> prevTxs =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        prevMonthStart,
        prevMonthEnd,
      );

      double prevIncome = 0;
      double prevExpense = 0;

      for (final tx in prevTxs) {
        if (tx.type == 'income') {
          prevIncome += tx.amount;
        } else if (tx.type == 'expense') {
          prevExpense += tx.amount;
        }
      }

      final prevProfit = prevIncome - prevExpense;

      double profitPercentageChange = 0.0;
      if (prevProfit != 0) {
        profitPercentageChange =
            ((currentProfit - prevProfit) / prevProfit) * 100;
      }

      double incomeChange = 0.0;
      if (prevIncome != 0) {
        incomeChange = ((currentIncome - prevIncome) / prevIncome) * 100;
      } else if (currentIncome != 0) {
        incomeChange = 100.0;
      }

      double expenseChange = 0.0;
      if (prevExpense != 0) {
        expenseChange = ((currentExpense - prevExpense) / prevExpense) * 100;
      } else if (currentExpense != 0) {
        expenseChange = 100.0;
      }

      setState(() {
        _monthlyProfit = currentProfit;
        _profitPercentageChange = profitPercentageChange;
        _incomeChange = incomeChange;
        _expenseChange = expenseChange;
        _isProfit = currentProfit >= 0;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      setState(() {
        _dashboardError = 'Failed to load dashboard data';
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _loadTopExpenses() async {
    setState(() {
      _isLoadingTopExpenses = true;
    });

    try {
      final now = DateTime.now();

      final currentMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      final currentMonthEnd =
          nextMonthStart.subtract(const Duration(milliseconds: 1));

      final List<TransactionRecord> transactions =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        currentMonthStart,
        currentMonthEnd,
      );

      final expenseTransactions =
          transactions.where((tx) => tx.type == 'expense').toList();

      final Map<String, double> categoryTotals = {};

      for (final tx in expenseTransactions) {
        if (tx.category.isEmpty) continue;
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      }

      final totalExpenses =
          categoryTotals.values.fold(0.0, (sum, v) => sum + v);

      final categoriesWithPercentages = categoryTotals.entries.map((entry) {
        final percentage =
            totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0.0;
        return {
          'categoryId': entry.key,
          'amount': entry.value,
          'percentage': percentage,
        };
      }).toList()
        ..sort(
          (a, b) =>
              (b['amount'] as double).compareTo(a['amount'] as double),
        );

      setState(() {
        _topExpenses = categoriesWithPercentages.take(3).toList();
        _isLoadingTopExpenses = false;
      });
    } catch (_) {
      setState(() {
        _topExpenses = [];
        _isLoadingTopExpenses = false;
        _dashboardError ??=
            'Some dashboard data could not be loaded. Pull to refresh to try again.';
      });
    }
  }

  Future<void> _loadCashBalanceData() async {
    setState(() {
      _isLoadingBalanceData = true;
    });

    try {
      final now = DateTime.now();

      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDate = endDate.subtract(const Duration(days: 29));
      final startDateNormalized =
          DateTime(startDate.year, startDate.month, startDate.day);

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
      double runningBalance = 0;

      for (int i = 0; i < 30; i++) {
        final date = startDateNormalized.add(Duration(days: i));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        runningBalance += dailyNetChanges[key] ?? 0;
        series.add({'date': date, 'balance': runningBalance});
      }

      setState(() {
        _balanceData = series;
        _isLoadingBalanceData = false;
      });
    } catch (_) {
      setState(() {
        _balanceData = [];
        _isLoadingBalanceData = false;
        _dashboardError ??=
            'Some dashboard data could not be loaded. Pull to refresh to try again.';
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _dashboardError = null;
    });

    await Future.wait([
      _loadMonthlyProfit(),
      _loadTopExpenses(),
      _loadCashBalanceData(),
    ]);
  }

  String _getGreeting() {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  String _getFormattedDate() {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(locale.toString()).format(DateTime.now());
  }

  String _getCategoryName(BuildContext context, String categoryId) {
    const labels = {
      'rev_sales': 'Sales and client income',
      'mkt_ads': 'Advertising and marketing',
      'mkt_software': 'Website and software',
      'mkt_subs': 'Subscriptions',
      'ops_equipment': 'Equipment and hardware',
      'ops_supplies': 'Office supplies',
      'pro_accounting': 'Accounting and legal',
      'pro_contractors': 'Contractors and outsourcing',
      'travel_general': 'Travel',
      'travel_meals': 'Meals and entertainment business',
      'ops_rent': 'Rent and utilities',
      'ops_insurance': 'Insurance',
      'ops_taxes': 'Taxes',
      'ops_fees': 'Bank and payment fees',
      'people_salary': 'Salary and payroll',
      'people_training': 'Benefits and training',
      'other_expense': 'Other expense',
      'other_refunds': 'Refunds and adjustments',
    };
    return labels[categoryId] ?? categoryId;
  }

  String _getCategoryIcon(String categoryId) {
    const icons = {
      'rev_sales': 'attach_money',
      'mkt_ads': 'campaign',
      'mkt_software': 'code',
      'mkt_subs': 'subscriptions',
      'ops_equipment': 'computer',
      'ops_supplies': 'inventory',
      'pro_accounting': 'gavel',
      'pro_contractors': 'people',
      'travel_general': 'flight',
      'travel_meals': 'restaurant',
      'ops_rent': 'home',
      'ops_insurance': 'shield',
      'ops_taxes': 'receipt_long',
      'ops_fees': 'account_balance',
      'people_salary': 'payments',
      'people_training': 'school',
      'other_expense': 'more_horiz',
      'other_refunds': 'sync',
    };
    return icons[categoryId] ?? 'category';
  }

  Future<void> _handleAddTransaction() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addTransaction);
    if (result == true) {
      await _handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(4.w, AppTheme.screenTopPadding, 4.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _getFormattedDate(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _isLoadingDashboard
                    ? Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        child: SizedBox(
                          height: 20.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : MonthlyProfitCard(
                        profit: _monthlyProfit,
                        percentageChange: _profitPercentageChange,
                        isProfit: _isProfit,
                        locale: _currencySettings.locale,
                        symbol: _currencySettings.symbol,
                        currencyCode: _currencySettings.currencyCode,
                      ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                  child: Text(
                    AppLocalizations.of(context)!.topExpenses,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _isLoadingTopExpenses
                    ? Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        child: SizedBox(
                          height: 18.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                        child: Row(
                          children: _topExpenses.asMap().entries.map((entry) {
                            final index = entry.key;
                            final e = entry.value;
                            final id = e['categoryId'] as String;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index < _topExpenses.length - 1 ? 2.w : 0,
                                ),
                                child: ExpenseCategoryCard(
                                  categoryName: _getCategoryName(context, id),
                                  categoryIcon: _getCategoryIcon(id),
                                  amount: e['amount'] as double,
                                  percentage: e['percentage'] as double,
                                  locale: _currencySettings.locale,
                                  symbol: _currencySettings.symbol,
                                  currencyCode:
                                      _currencySettings.currencyCode,
                                  onTap: null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              SliverToBoxAdapter(
                child: _isLoadingBalanceData
                    ? Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        child: SizedBox(
                          height: 28.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : CashBalanceChart(
                        balanceData: _balanceData,
                        locale: _currencySettings.locale,
                        symbol: _currencySettings.symbol,
                        currencyCode:
                            _currencySettings.currencyCode,
                      ),
              ),
              SliverToBoxAdapter(
                child: ComparisonMetricsCard(
                  incomeChange: _incomeChange,
                  expenseChange: _expenseChange,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.dashboard,
        onItemSelected: (_) {},
        onAddTransaction: _handleAddTransaction,
      ),
    );
  }
}