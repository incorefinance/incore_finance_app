import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_settings_service.dart';

import '../../core/app_export.dart';
import '../../main.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/cash_balance_chart.dart';
import './widgets/comparison_metrics_card.dart';
import './widgets/expense_category_card.dart';
import './widgets/monthly_profit_card.dart';

/// Dashboard Home Screen - Primary financial overview
/// Displays monthly profit, top expenses, cash balance trend, and comparisons
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool _isRefreshing = false;

  // Repository and real state fields
  final TransactionsRepository _transactionsRepository =
      TransactionsRepository();
  final UserSettingsService _userSettingsService = UserSettingsService();

  double _monthlyProfit = 0.0;
  double _profitPercentageChange = 0.0;
  bool _isProfit = true;

  bool _isLoadingDashboard = true;
  String? _dashboardError;

  // Currency settings
  UserCurrencySettings _currencySettings = const UserCurrencySettings(
    currencyCode: 'EUR',
    symbol: '€',
    locale: 'pt_PT',
  );

  // Real top expenses data loaded from Supabase
  List<Map<String, dynamic>> _topExpenses = [];
  bool _isLoadingTopExpenses = true;

  // Real cash balance data for 30 days
  List<Map<String, dynamic>> _balanceData = [];
  bool _isLoadingBalanceData = true;

  // Month-over-month percentage changes (real data)
  double _incomeChange = 0.0;
  double _expenseChange = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings();
    _loadCashBalanceData();
    _loadMonthlyProfit();
    _loadTopExpenses();
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      setState(() {
        _currencySettings = settings;
      });
    } catch (e) {
      // Use default EUR settings if loading fails
    }
  }

  Future<void> _loadMonthlyProfit() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final now = DateTime.now();

      // Current month range
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      final currentMonthEnd = nextMonthStart.subtract(const Duration(days: 1));

      final List<TransactionRecord> currentTxs =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        currentMonthStart,
        currentMonthEnd,
      );

      double currentIncome = 0;
      double currentExpense = 0;

      for (final tx in currentTxs) {
        final type = tx.type;
        final amount = tx.amount;

        if (type == 'income') {
          currentIncome += amount;
        } else if (type == 'expense') {
          currentExpense += amount;
        }
      }

      final currentProfit = currentIncome - currentExpense;

      // Previous month range
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
        final type = tx.type;
        final amount = tx.amount;

        if (type == 'income') {
          prevIncome += amount;
        } else if (type == 'expense') {
          prevExpense += amount;
        }
      }

      final prevProfit = prevIncome - prevExpense;

      // Profit percentage change month over month
      double profitPercentageChange = 0.0;
      if (prevProfit != 0) {
        profitPercentageChange =
            ((currentProfit - prevProfit) / prevProfit) * 100;
      }

      // Income month over month change
      double incomeChange = 0.0;
      if (prevIncome != 0) {
        incomeChange = ((currentIncome - prevIncome) / prevIncome) * 100;
      } else if (currentIncome != 0) {
        // No previous income but we have income now
        incomeChange = 100.0;
      }

      // Expenses month over month change
      double expenseChange = 0.0;
      if (prevExpense != 0) {
        expenseChange = ((currentExpense - prevExpense) / prevExpense) * 100;
      } else if (currentExpense != 0) {
        // No previous expenses but we have expenses now
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
    } catch (e) {
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

      // Current month range
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      final currentMonthEnd = nextMonthStart.subtract(const Duration(days: 1));

      final List<TransactionRecord> transactions =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        currentMonthStart,
        currentMonthEnd,
      );

      // Filter only expense transactions
      final expenseTransactions =
          transactions.where((tx) => tx.type == 'expense').toList();

      // Aggregate by category
      final Map<String, double> categoryTotals = {};

      for (final tx in expenseTransactions) {
        final category = tx.category;
        final amount = tx.amount;

        if (category.isEmpty) continue;

        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }

      final totalExpenses = categoryTotals.values.fold<double>(
        0.0,
        (sum, value) => sum + value,
      );

      // Convert to list with percentages
      final categoriesWithPercentages = categoryTotals.entries.map((entry) {
        final amount = entry.value;
        final percentage =
            totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
        return {
          'categoryId': entry.key,
          'amount': amount,
          'percentage': percentage,
        };
      }).toList();

      // Sort by amount descending and take top 3
      categoriesWithPercentages.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );
      final topCategories = categoriesWithPercentages.take(3).toList();

      setState(() {
        _topExpenses = topCategories;
        _isLoadingTopExpenses = false;
      });
    } catch (e) {
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

      // Calculate 30 day window (including today)
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDate = endDate.subtract(const Duration(days: 29));
      final startDateNormalized = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      // Fetch all transactions for the 30 day period
      final List<TransactionRecord> transactions =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        startDateNormalized,
        endDate,
      );

      // Create a map to store daily net changes
      final Map<String, double> dailyNetChanges = {};

      // Initialize all 30 days with zero net change
      for (int i = 0; i < 30; i++) {
        final date = startDateNormalized.add(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyNetChanges[dateKey] = 0.0;
      }

      // Process transactions and calculate daily net changes
      for (final tx in transactions) {
        final txDate = tx.date;
        final txNormalizedDate = DateTime(txDate.year, txDate.month, txDate.day);
        final dateKey =
            '${txNormalizedDate.year}-${txNormalizedDate.month.toString().padLeft(2, '0')}-${txNormalizedDate.day.toString().padLeft(2, '0')}';
        final type = tx.type;
        final amount = tx.amount;

        if (dailyNetChanges.containsKey(dateKey)) {
          if (type == 'income') {
            dailyNetChanges[dateKey] =
                (dailyNetChanges[dateKey] ?? 0.0) + amount;
          } else if (type == 'expense') {
            dailyNetChanges[dateKey] =
                (dailyNetChanges[dateKey] ?? 0.0) - amount;
          }
        }
      }

      // Build running balance series
      final List<Map<String, dynamic>> balanceSeries = [];
      double runningBalance = 0.0;

      for (int i = 0; i < 30; i++) {
        final date = startDateNormalized.add(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        // Add daily net change to running balance
        runningBalance += dailyNetChanges[dateKey] ?? 0.0;

        balanceSeries.add({'date': date, 'balance': runningBalance});
      }

      setState(() {
        _balanceData = balanceSeries;
        _isLoadingBalanceData = false;
      });
    } catch (e) {
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
      _isRefreshing = true;
      _dashboardError = null;
    });

    await Future.wait([
      _loadMonthlyProfit(),
      _loadTopExpenses(),
      _loadCashBalanceData(),
    ]);

    setState(() {
      _isRefreshing = false;
    });
  }

  void _toggleLanguage() {
    final currentLocale = Localizations.localeOf(context);
    final newLocale = currentLocale.languageCode == 'en'
        ? const Locale('pt')
        : const Locale('en');
    MyApp.setLocale(context, newLocale);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(locale.toString()).format(now);
  }

  String _getCategoryName(BuildContext context, String categoryId) {
    // Map category ID to display name
    const categoryLabels = {
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
    return categoryLabels[categoryId] ?? categoryId;
  }

  String _getCategoryIcon(String categoryId) {
    const iconMap = {
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
    return iconMap[categoryId] ?? 'category';
  }

  void _handleCategoryTap(String categoryId) {
    final categoryName = _getCategoryName(context, categoryId);
    // Navigate to transactions list with category filter applied
    Navigator.pushNamed(
      context,
      AppRoutes.transactionsList,
      arguments: {
        'prefilter': {'categoryId': categoryId, 'categoryName': categoryName},
      },
    );
  }

  Future<void> _handleAddTransaction() async {
    // Navigate to Add Transaction screen and wait for result
    final result = await Navigator.pushNamed(context, AppRoutes.addTransaction);

    // If transaction was added successfully, reload the dashboard data
    if (result == true) {
      await _loadMonthlyProfit();
      await _loadTopExpenses();
      await _loadCashBalanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        variant: AppBarVariant.transparent,
        title: 'Dashboard',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'language',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _toggleLanguage,
            tooltip: currentLocale.languageCode == 'en'
                ? 'Switch to Portuguese'
                : 'Switch to English',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.accentGold,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Section
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
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

                    // Global dashboard error banner
                    if (_dashboardError != null) ...[
                      SizedBox(height: 1.5.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: colorScheme.onErrorContainer,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _dashboardError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _handleRefresh,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Retry',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Monthly Profit Card
            SliverToBoxAdapter(
              child: _isLoadingDashboard
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: SizedBox(
                        height: 20.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentGold,
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
                    ),
            ),

            // Top 3 Expense Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Text(
                  'Top Expenses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoadingTopExpenses
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: SizedBox(
                        height: 18.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                    )
                  : _topExpenses.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'No expenses recorded this month yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 24.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            itemCount: _topExpenses.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 3.w),
                            itemBuilder: (context, index) {
                              final expense = _topExpenses[index];
                              final categoryId =
                                  expense['categoryId'] as String;
                              return ExpenseCategoryCard(
                                categoryName: _getCategoryName(
                                  context,
                                  categoryId,
                                ),
                                categoryIcon: _getCategoryIcon(categoryId),
                                amount: expense['amount'] as double,
                                percentage: expense['percentage'] as double,
                                locale: _currencySettings.locale,
                                symbol: _currencySettings.symbol,
                                onTap: () => _handleCategoryTap(categoryId),
                              );
                            },
                          ),
                        ),
            ),

            // Cash Balance Trend Chart
            SliverToBoxAdapter(
              child: _isLoadingBalanceData
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: SizedBox(
                        height: 28.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                    )
                  : CashBalanceChart(
                      balanceData: _balanceData,
                      locale: _currencySettings.locale,
                      symbol: _currencySettings.symbol,
                    ),
            ),

            // Month-over-Month Comparison
            SliverToBoxAdapter(
              child: ComparisonMetricsCard(
                incomeChange: _incomeChange,
                expenseChange: _expenseChange,
              ),
            ),

            // Bottom spacing for FAB
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        ),
      ), 
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.dashboard,
        onItemSelected: (item) {},
        onAddTransaction: _handleAddTransaction,
      ),
    );
  }
}
