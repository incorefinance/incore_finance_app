import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/number_formatter.dart';

/// Profit trends line chart widget
class ProfitTrendsChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> trendData;
  final String locale;
  final String symbol;
  final String currencyCode;

  const ProfitTrendsChartWidget({
    super.key,
    required this.trendData,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  @override
  State<ProfitTrendsChartWidget> createState() => _ProfitTrendsChartWidgetState();
}

class _ProfitTrendsChartWidgetState extends State<ProfitTrendsChartWidget> {
  List<int> showingTooltipOnSpots = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Use your main accent instead of gold
    final accent = AppColors.primarySoft;

    final xMax = (widget.trendData.length - 1).toDouble();
    const double xPadding = 0.25;

    return Semantics(
      label: "Profit Trends Line Chart showing profit history",
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.primary.withValues(alpha: 0.9),
              tooltipPadding: EdgeInsets.all(2.w),
              tooltipMargin: 2.h,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final month =
                      widget.trendData[barSpot.x.toInt()]['month'] as String;
                  final profit = barSpot.y;
                  final formattedProfit = IncoreNumberFormatter.formatMoney(
                    profit,
                    locale: widget.locale,
                    symbol: widget.symbol,
                    currencyCode: widget.currencyCode,
                  );
                  return LineTooltipItem(
                    '$month\nProfit: $formattedProfit',
                    theme.textTheme.bodySmall!.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: accent,
                    strokeWidth: 2,
                    dashArray: [5, 5],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 1.2.w,
                        color: accent,
                        strokeWidth: 1.5,
                        strokeColor: AppColors.surface,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getNiceYAxisInterval(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.borderSubtle.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
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
                reservedSize: 4.h,
                interval: _getXAxisInterval(),
                getTitlesWidget: (value, meta) {
                  // Only show labels for integer ticks (avoid duplicates like Jan26 twice)
                  if ((value - value.round()).abs() > 1e-6) {
                    return const SizedBox.shrink();
                  }

                  final index = value.round();
                  if (index < 0 || index >= widget.trendData.length) {
                    return const SizedBox.shrink();
                  }

                  final month = widget.trendData[index]['month'] as String;

                  return Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      month,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
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
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: -xPadding,
          maxX: xMax + xPadding,
          minY: (_getMinValue() >= 0) ? 0 : _getMinValue() * 1.1,
          maxY: _getNiceMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: _buildSpots(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 1.0.w,
                    color: accent,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getXAxisInterval() {
    final count = widget.trendData.length;

    if (count <= 3) return 1;
    if (count <= 6) return 2;
    return 3;
  }

  List<FlSpot> _buildSpots() {
    return List.generate(
      widget.trendData.length,
      (index) => FlSpot(
        index.toDouble(),
        (widget.trendData[index]['profit'] as num).toDouble(),
      ),
    );
  }

  double _getMaxValue() {
    return widget.trendData.fold<double>(
      0,
      (max, item) {
        final profit = (item['profit'] as num).toDouble();
        return profit > max ? profit : max;
      },
    );
  }

  double _getMinValue() {
    return widget.trendData.fold<double>(
      double.infinity,
      (min, item) {
        final profit = (item['profit'] as num).toDouble();
        return profit < min ? profit : min;
      },
    );
  }

  double _getNiceYAxisInterval() {
    final max = _getMaxValue();
    if (max <= 0) return 100;

    // Aim for ~4 grid lines
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

  String _formatYAxisValue(double value) {
    final interval = _getNiceYAxisInterval();
    if (!_isMultipleOf(value, interval)) return '';

    final abs = value.abs();

    if (abs >= 1000) {
      final k = value / 1000.0;
      final needsDecimal = (interval % 1000 != 0);
      final txt = needsDecimal ? k.toStringAsFixed(1) : k.toStringAsFixed(0);
      return '${widget.symbol}${txt}k';
    }

    return '${widget.symbol}${value.toStringAsFixed(0)}';
  }

  double _getNiceMaxY() {
    final max = _getMaxValue();
    if (max <= 0) return 1000;

    final interval = _getNiceYAxisInterval();
    final niceTop = (max / interval).ceil() * interval;
    return niceTop * 1.02;
  }

  bool _isMultipleOf(double value, double step) {
    if (step == 0) return false;
    final m = value / step;
    return (m - m.round()).abs() < 1e-6;
  }
}
