import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';

class CashBalanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> balanceData;
  final String locale;
  final String symbol;
  final String currencyCode;

  const CashBalanceChart({
    super.key,
    required this.balanceData,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final uiLocale = Localizations.localeOf(context).toString();

    final maxY = _getNiceMaxY();
    final interval = _getNiceYAxisInterval();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 28.h, maxHeight: 35.h),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.cashBalanceTrend,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.thirtyDays,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withValues(alpha: 0.10),
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
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= balanceData.length) {
                          return const SizedBox.shrink();
                        }
                        final date = balanceData[i]['date'] as DateTime;
                        return Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Text(
                            '${date.day}/${date.month}',
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
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                    tooltipBgColor: AppColors.textPrimary.withValues(alpha: 0.92),
                    tooltipRoundedRadius: 10,
                    tooltipPadding: EdgeInsets.all(2.w),
                    getTooltipItems: (spots) {
                      return spots.map((barSpot) {
                        final date =
                            balanceData[barSpot.x.toInt()]['date'] as DateTime;
                        final balance = barSpot.y;

                        final formattedAmount = IncoreNumberFormatter.formatMoney(
                          balance,
                          locale: locale,
                          symbol: symbol,
                          currencyCode: currencyCode,
                        );

                        return LineTooltipItem(
                          '${DateFormat('MMM d', uiLocale).format(date)}\n$formattedAmount',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
                    color: AppColors.primarySoft,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.primarySoft,
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
                          AppColors.primarySoft.withValues(alpha: 0.22),
                          AppColors.primarySoft.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
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
