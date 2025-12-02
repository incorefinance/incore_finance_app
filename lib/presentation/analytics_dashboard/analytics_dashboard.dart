import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/category_breakdown_chart_widget.dart';
import './widgets/chart_section_widget.dart';
import './widgets/date_range_selector_widget.dart';
import './widgets/financial_ratio_card_widget.dart';
import './widgets/income_expenses_chart_widget.dart';
import './widgets/profit_trends_chart_widget.dart';

/// Analytics Dashboard screen for comprehensive financial insights
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedChartType = 1;
  String _selectedDateRange = 'Last 30 days';
  bool _isLoading = false;

  // Currency settings
  String _currencyLocale = 'en_US';
  String _currencySymbol = '\$';

  // Mock data for Income vs Expenses
  final List<Map<String, dynamic>> _incomeExpensesData = [
    {'month': 'Jul', 'income': 8500, 'expenses': 6200},
    {'month': 'Aug', 'income': 9200, 'expenses': 6800},
    {'month': 'Sep', 'income': 7800, 'expenses': 5900},
    {'month': 'Oct', 'income': 10500, 'expenses': 7200},
    {'month': 'Nov', 'income': 9800, 'expenses': 6500},
    {'month': 'Dec', 'income': 11200, 'expenses': 7800},
  ];

  // Mock data for Category Breakdown
  final List<Map<String, dynamic>> _categoryData = [
    {'category': 'Software & Tools', 'amount': 2400},
    {'category': 'Marketing', 'amount': 1800},
    {'category': 'Office Supplies', 'amount': 950},
    {'category': 'Travel', 'amount': 1200},
    {'category': 'Professional Services', 'amount': 1500},
    {'category': 'Utilities', 'amount': 650},
    {'category': 'Insurance', 'amount': 800},
    {'category': 'Miscellaneous', 'amount': 500},
  ];

  // Mock data for Profit Trends
  final List<Map<String, dynamic>> _profitTrendsData = [
    {'month': 'Jul', 'profit': 2300},
    {'month': 'Aug', 'profit': 2400},
    {'month': 'Sep', 'profit': 1900},
    {'month': 'Oct', 'profit': 3300},
    {'month': 'Nov', 'profit': 3300},
    {'month': 'Dec', 'profit': 3400},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings();
  }

  Future<void> _loadCurrencySettings() async {
    // Remove the call to non-existent getCurrencySettings method
    // Use default currency settings instead
    setState(() {
      _currencyLocale = 'en_US';
      _currencySymbol = '\$';
    });
  }

  /// Get dynamic subtitle based on selected date range and chart type
  String _getChartSubtitle() {
    if (_selectedChartType == 3) {
      // Profit Trends - dynamic subtitle
      switch (_selectedDateRange) {
        case 'Last 30 days':
          return '30-day profit history and analysis';
        case 'Last 3 months':
          return '3-month profit history and analysis';
        case 'Last 6 months':
          return '6-month profit history and analysis';
        default:
          return '6-month profit history and analysis';
      }
    } else if (_selectedChartType == 1) {
      return 'Monthly comparison of income and expenses';
    } else if (_selectedChartType == 2) {
      return 'Expense distribution by category';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Analytics',
        variant: AppBarVariant.standard,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: AppTheme.primaryNavyLight,
              size: 24,
            ),
            onPressed: _handleExport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.accentGold,
        child: CustomScrollView(
          slivers: [
            // Horizontally Scrollable Tab Navigation - LARGER AND MORE PROMINENT
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                height: 7.h,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton('Income vs Expenses', 1),
                      SizedBox(width: 2.w),
                      _buildTabButton('Category Breakdown', 2),
                      SizedBox(width: 2.w),
                      _buildTabButton('Profit Trends', 3),
                    ],
                  ),
                ),
              ),
            ),

            // Date Range Selector
            SliverToBoxAdapter(
              child: DateRangeSelectorWidget(
                selectedRange: _selectedDateRange,
                onRangeChanged: (range) {
                  setState(() {
                    _selectedDateRange = range;
                  });
                  _handleDateRangeChange(range);
                },
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 2.h)),

            // Chart Section
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : AnimatedSwitcher(
                      duration: AppTheme.mediumDuration,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildChartSection(),
                    ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 3.h)),

            // Financial Ratios Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Key Financial Ratios',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 2.h)),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 2.h,
                  childAspectRatio: 2.5,
                ),
                delegate: SliverChildListDelegate([
                  FinancialRatioCardWidget(
                    title: 'Profit Margin',
                    value: '32.4%',
                    description:
                        'Percentage of revenue remaining after expenses',
                    indicatorColor: AppTheme.successGreen,
                    icon: Icons.percent,
                  ),
                  FinancialRatioCardWidget(
                    title: 'Burn Rate',
                    value: '\$6,800/mo',
                    description: 'Average monthly spending rate',
                    indicatorColor: AppTheme.warningAmber,
                    icon: Icons.local_fire_department,
                  ),
                  FinancialRatioCardWidget(
                    title: 'Runway',
                    value: '8.5 months',
                    description:
                        'Time until funds are depleted at current rate',
                    indicatorColor: AppTheme.accentGold,
                    icon: Icons.flight_takeoff,
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.analytics,
        onItemSelected: (item) {
          // Navigation handled by CustomBottomBar
        },
      ),
    );
  }

  Widget _buildTabButton(String text, int value) {
    final bool isSelected = _selectedChartType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = value;
        });
      },
      child: AnimatedContainer(
        duration: AppTheme.mediumDuration,
        curve: AppTheme.defaultCurve,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryNavyLight
              : AppTheme.neutralGray.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, // Semi-bold
              fontSize: 14.sp, // Increased font size
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentChild(String text, int value) {
    // This method is no longer needed but kept for compatibility
    final bool isSelected = _selectedChartType == value;

    return Center(
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _buildChartSection() {
    switch (_selectedChartType) {
      case 1:
        return ChartSectionWidget(
          key: const ValueKey('income-expenses'),
          title: 'Income vs Expenses',
          subtitle: _getChartSubtitle(),
          chart: IncomeExpensesChartWidget(
            chartData: _incomeExpensesData,
            locale: _currencyLocale,
            symbol: _currencySymbol,
          ),
        );
      case 2:
        return ChartSectionWidget(
          key: const ValueKey('category-breakdown'),
          title: 'Category Breakdown',
          subtitle: _getChartSubtitle(),
          chart: CategoryBreakdownChartWidget(
            categoryData: _categoryData,
            locale: _currencyLocale,
            symbol: _currencySymbol,
          ),
        );
      case 3:
        return ChartSectionWidget(
          key: const ValueKey('profit-trends'),
          title: 'Profit Trends',
          subtitle: _getChartSubtitle(),
          chart: ProfitTrendsChartWidget(
            trendData: _profitTrendsData,
            locale: _currencyLocale,
            symbol: _currencySymbol,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: AppTheme.neutralGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            width: 60.w,
            height: 1.5.h,
            decoration: BoxDecoration(
              color: AppTheme.neutralGray.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            height: 30.h,
            decoration: BoxDecoration(
              color: AppTheme.neutralGray.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Analytics data refreshed'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleDateRangeChange(String range) {
    // In a real app, this would fetch data for the selected date range
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading data for: $range'),
        backgroundColor: AppTheme.primaryNavyLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleExport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Analytics',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                SizedBox(height: 2.h),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'picture_as_pdf',
                    color: AppTheme.errorRed,
                    size: 24,
                  ),
                  title: const Text('Export as PDF'),
                  subtitle: const Text('Generate comprehensive PDF report'),
                  onTap: () {
                    Navigator.pop(context);
                    _showExportSuccess('PDF');
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'table_chart',
                    color: AppTheme.successGreen,
                    size: 24,
                  ),
                  title: const Text('Export as CSV'),
                  subtitle: const Text('Download data in spreadsheet format'),
                  onTap: () {
                    Navigator.pop(context);
                    _showExportSuccess('CSV');
                  },
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExportSuccess(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$format report exported successfully'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: AppTheme.surfaceLight,
          onPressed: () {
            // Open exported file
          },
        ),
      ),
    );
  }
}