import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_colors_ext.dart';
import '../../../utils/number_formatter.dart';
import 'chart_constants.dart';

class CashBalanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> balanceData;
  final String locale;
  final String symbol;
  final String currencyCode;
  final Set<int> transactionIndices;

  const CashBalanceChart({
    super.key,
    required this.balanceData,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    required this.transactionIndices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uiLocale = Localizations.localeOf(context).toString();

    final maxY = _getNiceMaxY();
    final interval = _getNiceYAxisInterval();

    // Chart content only - container/header provided by _buildChartCard wrapper
    return LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withValues(
                        alpha: AnalyticsChartConstants.gridLineAlpha),
                    strokeWidth: 1,
                  ),
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
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= balanceData.length) {
                          return const SizedBox.shrink();
                        }
                        // Dynamic labeling based on data length
                        final bool isKeyIndex = _isKeyXAxisIndex(i, balanceData.length);
                        if (!isKeyIndex) {
                          return const SizedBox.shrink();
                        }
                        final rawDate = balanceData[i]['date'];
                        final date = rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());
                        // Use month abbreviation for longer ranges
                        final String label = balanceData.length > 90
                            ? DateFormat('MMM', uiLocale).format(date)
                            : '${date.day}/${date.month}';
                        return Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 12.w,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final txt = _formatYAxisValue(value);
                        if (txt.isEmpty) return const SizedBox.shrink();
                        return Text(
                          txt,
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (balanceData.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AnalyticsChartConstants.tooltipBackground(),
                    tooltipRoundedRadius: AnalyticsChartConstants.tooltipRadius,
                    tooltipPadding: EdgeInsets.all(2.w),
                    getTooltipItems: (spots) {
                      return spots.map((barSpot) {
                        final rawDate = balanceData[barSpot.x.toInt()]['date'];
                        final date = rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());
                        final balance = barSpot.y;

                        final formattedAmount = IncoreNumberFormatter.formatMoney(
                          balance,
                          locale: locale,
                          symbol: symbol,
                          currencyCode: currencyCode,
                        );

                        return LineTooltipItem(
                          '${DateFormat('MMM d', uiLocale).format(date)}\n$formattedAmount',
                          theme.textTheme.bodySmall!.copyWith(
                            color: context.surface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: balanceData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        (e.value['balance'] as num).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: context.blue600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        // Only show dots on days with transactions
                        return transactionIndices.contains(spot.x.toInt());
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: context.blue600,
                          strokeWidth: 1.5,
                          strokeColor: colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.blue600.withValues(alpha: 0.22),
                          context.blue600.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  double _getMaxValue() {
    if (balanceData.isEmpty) return 0;
    double max = 0;
    for (final item in balanceData) {
      final v = (item['balance'] as num).toDouble();
      if (v > max) max = v;
    }
    return max;
  }

  double _getNiceYAxisInterval() {
    final max = _getMaxValue();
    if (max <= 0) return 100;

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
    return (max / interval).ceil() * interval;
  }

  /// Determines if the given index should display an x-axis label
  /// based on the total data length.
  /// - <= 30 days: Weekly (0, 7, 14, 21, last)
  /// - <= 90 days: Bi-weekly intervals
  /// - <= 180 days: Monthly intervals (~30 days)
  /// - > 180 days: Bi-monthly intervals (~60 days)
  bool _isKeyXAxisIndex(int index, int length) {
    if (length <= 0) return false;
    final lastIndex = length - 1;

    // Always show first and last
    if (index == 0 || index == lastIndex) return true;

    // Avoid overlap: skip index right before last
    if (index == lastIndex - 1) return false;

    if (length <= 30) {
      // Weekly: 0, 7, 14, 21, last
      return index == 7 || index == 14 || index == 21;
    } else if (length <= 90) {
      // Bi-weekly (~14 day intervals)
      return index % 14 == 0;
    } else if (length <= 180) {
      // Monthly (~30 day intervals)
      return index % 30 == 0;
    } else {
      // Bi-monthly (~60 day intervals)
      return index % 60 == 0;
    }
  }

  String _formatYAxisValue(double value) {
    final interval = _getNiceYAxisInterval();
    if (interval <= 0) return '';

    if (value.abs() < 1e-6) return '${symbol}0';

    final snapped = (value / interval).round() * interval;
    final isTick = (value - snapped).abs() < (interval * 0.001);
    if (!isTick) return '';

    final abs = snapped.abs();
    if (abs >= 1000) {
      final k = snapped / 1000.0;
      final needsDecimal = (interval % 1000 != 0);
      final txt = needsDecimal ? k.toStringAsFixed(1) : k.toStringAsFixed(0);
      return '${symbol}${txt}k';
    }

    return '${symbol}${snapped.toStringAsFixed(0)}';
  }
}
