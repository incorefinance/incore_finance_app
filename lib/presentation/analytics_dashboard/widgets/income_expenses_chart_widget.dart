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
  final String currencyCode;

  const IncomeExpensesChartWidget({
    super.key,
    required this.chartData,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
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
          alignment: BarChartAlignment.spaceBetween,
          groupsSpace: 3.w,
          maxY: _getNiceMaxY(),
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
                    IncoreNumberFormatter.formatMoney(
                  value,
                  locale: widget.locale,
                  symbol: widget.symbol,
                  currencyCode: widget.currencyCode,
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
                  final index = value.toInt();
                  final len = widget.chartData.length;
                  if (index < 0 || index >= len) return const SizedBox.shrink();

                  final first = _firstNonZeroMonthIndex();
                  final last = _lastNonZeroMonthIndex();

                  if (!_shouldShowMonthLabel(index, first, last)) {
                    return const SizedBox.shrink();
                  }

                  final month = widget.chartData[index]['month'] as String;

                  return Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(month, style: AppTheme.lightTheme.textTheme.bodySmall),
                  );
                },
                reservedSize: 4.h,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 12.w,
                interval: _getNiceYAxisInterval(),
                getTitlesWidget: (value, meta) {
                  final text = _formatYAxisValue(value);
                  if (text.isEmpty) return const SizedBox.shrink();

                  return Text(
                    text,
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
            horizontalInterval: _getNiceYAxisInterval(),
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

  int _firstNonZeroMonthIndex() {
    for (var i = 0; i < widget.chartData.length; i++) {
      final m = widget.chartData[i];
      final income = (m['income'] as num).toDouble();
      final expenses = (m['expenses'] as num).toDouble();
      if (income != 0 || expenses != 0) return i;
    }
    return 0;
  }

  int _lastNonZeroMonthIndex() {
    for (var i = widget.chartData.length - 1; i >= 0; i--) {
      final m = widget.chartData[i];
      final income = (m['income'] as num).toDouble();
      final expenses = (m['expenses'] as num).toDouble();
      if (income != 0 || expenses != 0) return i;
    }
    return widget.chartData.length - 1;
  }

  bool _shouldShowMonthLabel(int index, int first, int last) {
    if (index == first || index == last) return true;

    final span = last - first;

    // For short ranges (3M style), show only first and last.
    if (span <= 2) return false;

    // For medium ranges (6M), show first, middle, last.
    if (span <= 6) {
      final mid = first + (span ~/ 2);
      return index == mid;
    }

    // For long ranges (12M), show every 2 months plus last.
    return ((index - first) % 2 == 0);
  }

  String _formatYAxisValue(double value) {
    final interval = _getNiceYAxisInterval();
    if (interval <= 0) return '';

    // Always show 0
    if (value.abs() < 1e-6) return '${widget.symbol}0';

    // Snap to the nearest tick to avoid float noise
    final snapped = (value / interval).round() * interval;

    // Only show labels for values that are very close to a tick
    final isTick = (value - snapped).abs() < (interval * 0.001);
    if (!isTick) return '';

    final abs = snapped.abs();

    if (abs >= 1000) {
      final k = snapped / 1000.0;

      // If interval is not a clean 1k multiple, allow one decimal (eg 2.5k)
      final needsDecimal = (interval % 1000 != 0);
      final txt = needsDecimal ? k.toStringAsFixed(1) : k.toStringAsFixed(0);

      return '${widget.symbol}${txt}k';
    }

    return '${widget.symbol}${snapped.toStringAsFixed(0)}';
  }


  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(widget.chartData.length, (index) {
      final data = widget.chartData[index];
      final isTouched = index == touchedIndex;

      final groupCount = widget.chartData.length;
      final rodWidth = groupCount >= 10 ? 6.0 : 10.0;
      final rodsSpace = groupCount >= 10 ? 4.0 : 6.0;

      return BarChartGroupData(
        x: index,
        barsSpace: rodsSpace,
        barRods: [
          BarChartRodData(
            toY: (data['income'] as num).toDouble(),
            color: isTouched
                ? AppTheme.successGreen
                : AppTheme.successGreen.withValues(alpha: 0.8),
            width: rodWidth,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          BarChartRodData(
            toY: (data['expenses'] as num).toDouble(),
            color: isTouched
                ? AppTheme.errorRed
                : AppTheme.errorRed.withValues(alpha: 0.8),
            width: rodWidth,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ],
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

  double _getNiceYAxisInterval() {
    final max = _getMaxValue();
    if (max <= 0) return 100;

    // Aim ~4 grid lines
    final raw = max / 4;

    const steps = <double>[
      50,
      100,
      250,
      500,
      1000,
      2500,
      5000,
      10000,
      25000,
      50000,
      100000,
    ];

    for (final s in steps) {
      if (raw <= s) return s;
    }
    return steps.last;
  }

  double _getNiceMaxY() {
    final max = _getMaxValue();
    if (max <= 0) return 1000;

    final interval = _getNiceYAxisInterval();

    // Round UP to next tick (your requirement)
    return (max / interval).ceil() * interval;
  }
}
