import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';

/// Cash balance trend chart widget
/// Displays 30-day balance trend with interactive line chart
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

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 28.h, maxHeight: 35.h),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
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
                  fontWeight: FontWeight.w600,
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

          // ✅ Minimal fix: chart expands to available height instead of forcing 25.h
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.1),
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
                      reservedSize: 30,
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < balanceData.length) {
                          final date =
                              balanceData[value.toInt()]["date"] as DateTime;
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '$symbol${(value / 1000).toStringAsFixed(0)}k',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                minX: 0,
                maxX: (balanceData.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxBalance() * 1.2,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: colorScheme.primary.withValues(alpha: 0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final date =
                            balanceData[barSpot.x.toInt()]['date'] as DateTime;
                        final balance = barSpot.y;

                        final formattedAmount =
                            IncoreNumberFormatter.formatMoney(
                              balance,
                              locale: locale,
                              symbol: symbol,
                              currencyCode: currencyCode,
                            );

                        return LineTooltipItem(
                          '${DateFormat('MMM d', uiLocale).format(date)}\n$formattedAmount',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: balanceData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value["balance"] as double),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.accentGold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.accentGold,
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
                          AppTheme.accentGold.withValues(alpha: 0.3),
                          AppTheme.accentGold.withValues(alpha: 0.05),
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

  double _getMaxBalance() {
    if (balanceData.isEmpty) return 5000;
    return balanceData
        .map((data) => data["balance"] as double)
        .reduce((a, b) => a > b ? a : b);
  }
}
