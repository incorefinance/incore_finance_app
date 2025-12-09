import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Income vs Expenses bar chart widget
class IncomeExpensesChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;
  final String locale;
  final String symbol;

  const IncomeExpensesChartWidget({
    super.key,
    required this.chartData,
    required this.locale,
    required this.symbol,
  });

  @override
  State<IncomeExpensesChartWidget> createState() =>
      _IncomeExpensesChartWidgetState();
}

class _IncomeExpensesChartWidgetState extends State<IncomeExpensesChartWidget> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Income vs Expenses Bar Chart showing monthly comparison",
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppTheme.primaryNavyLight.withValues(alpha: 0.9),
              tooltipPadding: EdgeInsets.all(2.w),
              tooltipMargin: 2.h,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month =
                    widget.chartData[group.x.toInt()]['month'] as String;
                final value = rod.toY;
                final type = rodIndex == 0 ? 'Income' : 'Expenses';
                final formattedValue =
                    IncoreNumberFormatter.formatAmountWithCurrency(
                  value,
                  locale: widget.locale,
                  symbol: widget.symbol,
                );
                return BarTooltipItem(
                  '$month\n$type: $formattedValue',
                  AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                    color: AppTheme.surfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  touchedIndex = null;
                  return;
                }
                touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= widget.chartData.length) {
                    return const SizedBox.shrink();
                  }
                  final month =
                      widget.chartData[value.toInt()]['month'] as String;
                  return Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      month,
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                  );
                },
                reservedSize: 4.h,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 12.w,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${widget.symbol}${(value / 1000).toStringAsFixed(0)}k',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(widget.chartData.length, (index) {
      final data = widget.chartData[index];
      final isTouched = index == touchedIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['income'] as num).toDouble(),
            color: isTouched
                ? AppTheme.successGreen
                : AppTheme.successGreen.withValues(alpha: 0.8),
            width: isTouched ? 4.w : 3.5.w,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          BarChartRodData(
            toY: (data['expenses'] as num).toDouble(),
            color: isTouched
                ? AppTheme.errorRed
                : AppTheme.errorRed.withValues(alpha: 0.8),
            width: isTouched ? 4.w : 3.5.w,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ],
        barsSpace: 1.w,
      );
    });
  }

  double _getMaxValue() {
    double max = 0;
    for (var data in widget.chartData) {
      final income = (data['income'] as num).toDouble();
      final expenses = (data['expenses'] as num).toDouble();
      if (income > max) max = income;
      if (expenses > max) max = expenses;
    }
    return max;
  }
}
