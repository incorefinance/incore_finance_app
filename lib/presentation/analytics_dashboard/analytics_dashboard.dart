import 'package:flutter/material.dart';
import 'package:incore_finance/widgets/custom_bottom_bar.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import './widgets/income_expenses_chart_widget.dart';
import './widgets/horizontal_category_breakdown_widget.dart';
import './widgets/profit_trends_chart_widget.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/models/transaction_category.dart';
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

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final TransactionsRepository _transactionsRepository = TransactionsRepository();

  bool _isLoading = true;
  String? _loadError;

  List<Map<String, dynamic>> _incomeExpensesData = [];
  List<Map<String, dynamic>> _profitTrendsData = [];
  List<Map<String, dynamic>> _incomeCategoryData = [];
  List<Map<String, dynamic>> _expenseCategoryData = [];

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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load analytics';
      });
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

  String _buildPerformanceSummaryText() {
    if (_profitTrendsData.length < 2) {
      return 'Not enough data yet to show trends.';
    }

    final last = (_profitTrendsData.last['profit'] as num).toDouble();
    final prev =
        (_profitTrendsData[_profitTrendsData.length - 2]['profit'] as num)
            .toDouble();

    final delta = last - prev;

    if (delta > 0) {
      return 'Profit improved compared to last month.';
    }
    if (delta < 0) {
      return 'Profit decreased compared to last month.';
    }
    return 'Profit was stable compared to last month.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: null, // ✅ removed app bar
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(child: Text(_loadError!))
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: SegmentedButton<_AnalyticsRange>(
                                segments: [
                                  ButtonSegment(
                                    value: _AnalyticsRange.m3,
                                    label: Text(
                                      AppLocalizations.of(context)!.threeMonths,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: _AnalyticsRange.m6,
                                    label: Text(
                                      AppLocalizations.of(context)!.sixMonths,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: _AnalyticsRange.m12,
                                    label: Text(
                                      AppLocalizations.of(context)!.twelveMonths,
                                    ),
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

                            // Section 1: Performance overview
                            Text(
                              AppLocalizations.of(context)!.performanceOverview,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            if (_profitTrendsData.isEmpty)
                              Text(AppLocalizations.of(context)!.notEnoughData),
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
                            const SizedBox(height: 16),
                            _PerformanceSummaryCard(
                              text: _buildPerformanceSummaryText(),
                            ),
                            const SizedBox(height: 24),

                            // Section 2: Income vs expenses
                            Text(
                              AppLocalizations.of(context)!.incomeVsExpensesChart,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (_incomeExpensesData.isEmpty)
                              Text(AppLocalizations.of(context)!.notEnoughData),
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
                            const SizedBox(height: 24),

                            // Section 3: Income sources
                            Text(
                              AppLocalizations.of(context)!.incomeSources,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            HorizontalCategoryBreakdownWidget(
                              data: _incomeCategoryData,
                              locale: _currencyLocale,
                              symbol: _currencySymbol,
                              currencyCode: _currencyCode,
                              accentColor: AppColors.income,
                            ),
                            const SizedBox(height: 32),

                            // Section 4: Expense breakdown
                            Text(
                              AppLocalizations.of(context)!.expenseBreakdown,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            HorizontalCategoryBreakdownWidget(
                              data: _expenseCategoryData,
                              locale: _currencyLocale,
                              symbol: _currencySymbol,
                              currencyCode: _currencyCode,
                              accentColor: AppColors.expense,
                            ),
                            const SizedBox(height: 24),

                            SizedBox(height: 3.h),
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

class _PerformanceSummaryCard extends StatelessWidget {
  final String text;

  const _PerformanceSummaryCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDecreased = text.toLowerCase().contains('decreased');
    final isImproved = text.toLowerCase().contains('improved');

    final accent = isDecreased
        ? AppColors.error
        : isImproved
            ? AppColors.success
            : AppColors.borderSubtle;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
      decoration: BoxDecoration(
        color: AppColors.borderSubtle.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
