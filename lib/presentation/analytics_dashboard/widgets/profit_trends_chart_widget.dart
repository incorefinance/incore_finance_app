import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';

/// Profit trends line chart widget
class ProfitTrendsChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> trendData;
  final String locale;
  final String symbol;

  const ProfitTrendsChartWidget({
    super.key,
    required this.trendData,
    required this.locale,
    required this.symbol,
  });

  @override
  State<ProfitTrendsChartWidget> createState() =>
      _ProfitTrendsChartWidgetState();
}

class _ProfitTrendsChartWidgetState extends State<ProfitTrendsChartWidget> {
  List<int> showingTooltipOnSpots = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 25.h,
          child: Semantics(
            label: "Profit Trends Line Chart showing 6-month profit history",
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor:
                        AppTheme.primaryNavyLight.withValues(alpha: 0.9),
                    tooltipPadding: EdgeInsets.all(2.w),
                    tooltipMargin: 2.h,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final month = widget.trendData[barSpot.x.toInt()]
                            ['month'] as String;
                        final profit = barSpot.y;
                        final formattedProfit =
                            IncoreNumberFormatter.formatAmountWithCurrency(
                          profit,
                          locale: widget.locale,
                          symbol: widget.symbol,
                        );
                        return LineTooltipItem(
                          '$month\nProfit: $formattedProfit',
                          AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                            color: AppTheme.surfaceLight,
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
                          color: AppTheme.accentGold,
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 2.w,
                              color: AppTheme.accentGold,
                              strokeWidth: 1.5,
                              strokeColor: AppTheme.surfaceLight,
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
                  horizontalInterval: _getMaxValue() / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.neutralGray.withValues(alpha: 0.3),
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
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= widget.trendData.length) {
                          return const SizedBox.shrink();
                        }
                        final month =
                            widget.trendData[value.toInt()]['month'] as String;
                        return Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Text(
                            month,
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                        );
                      },
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
                minX: 0,
                maxX: (widget.trendData.length - 1).toDouble(),
                minY: _getMinValue() * 0.9,
                maxY: _getMaxValue() * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildSpots(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.accentGold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 1.5.w,
                          color: AppTheme.accentGold,
                          strokeWidth: 2,
                          strokeColor: AppTheme.surfaceLight,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentGold.withValues(alpha: 0.3),
                          AppTheme.accentGold.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        _buildTrendAnalysis(),
      ],
    );
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

  Widget _buildTrendAnalysis() {
    if (widget.trendData.length < 2) {
      return const SizedBox.shrink();
    }

    final firstProfit = (widget.trendData.first['profit'] as num).toDouble();
    final lastProfit = (widget.trendData.last['profit'] as num).toDouble();
    final change = lastProfit - firstProfit;
    final percentChange = (change / firstProfit * 100);
    final isPositive = change >= 0;

    final formattedChange = IncoreNumberFormatter.formatAmountWithCurrency(
      change.abs(),
      locale: widget.locale,
      symbol: widget.symbol,
    );

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isPositive
            ? AppTheme.successGreen.withValues(alpha: 0.1)
            : AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isPositive ? 'trending_up' : 'trending_down',
            color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '6-Month Trend Analysis',
                  style: AppTheme.lightTheme.textTheme.titleSmall,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Your profit has ${isPositive ? 'increased' : 'decreased'} by $formattedChange (${percentChange.abs().toStringAsFixed(1)}%) over the last 6 months.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
