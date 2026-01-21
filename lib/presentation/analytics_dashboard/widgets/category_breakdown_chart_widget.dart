import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Category breakdown pie chart widget
class CategoryBreakdownChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> categoryData;
  final String locale;
  final String symbol;
  final String currencyCode;

  const CategoryBreakdownChartWidget({
    super.key,
    required this.categoryData,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  @override
  State<CategoryBreakdownChartWidget> createState() =>
      _CategoryBreakdownChartWidgetState();
}

class _CategoryBreakdownChartWidgetState
    extends State<CategoryBreakdownChartWidget> {
  int? touchedIndex;

  final List<Color> _colors = [
    AppTheme.primaryNavyLight,
    AppTheme.accentGold,
    AppTheme.successGreen,
    AppTheme.warningAmber,
    AppTheme.errorRed,
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Add top padding to prevent clipping
          SizedBox(height: 2.h),
          Container(
            height: 22.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Semantics(
              label:
                  "Category Breakdown Pie Chart showing expense distribution",
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = null;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 8.w,
                  sections: _buildPieSections(),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = widget.categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    return List.generate(widget.categoryData.length, (index) {
      final data = widget.categoryData[index];
      final isTouched = index == touchedIndex;
      final amount = (data['amount'] as num).toDouble();
      final percentage = (amount / total * 100);

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 13.w : 11.w,
        titleStyle: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          color: AppTheme.surfaceLight,
          fontWeight: FontWeight.w600,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  Widget _buildLegend() {
    final total = widget.categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    return Wrap(
      spacing: 3.w,
      runSpacing: 1.5.h,
      alignment: WrapAlignment.center,
      children: List.generate(widget.categoryData.length, (index) {
        final data = widget.categoryData[index];
        final amount = (data['amount'] as num).toDouble();
        final percentage = (amount / total * 100);
        final formattedAmount = IncoreNumberFormatter.formatMoney(
          amount,
          locale: widget.locale,
          symbol: widget.symbol,
          currencyCode: widget.currencyCode,
        );

        return InkWell(
          onTap: () {
            setState(() {
              touchedIndex = touchedIndex == index ? null : index;
            });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
            decoration: BoxDecoration(
              color: touchedIndex == index
                  ? _colors[index % _colors.length].withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: touchedIndex == index
                    ? _colors[index % _colors.length]
                    : AppTheme.neutralGray,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2.5.w,
                  height: 2.5.w,
                  decoration: BoxDecoration(
                    color: _colors[index % _colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.5.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data['category'] as String,
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$formattedAmount (${percentage.toStringAsFixed(1)}%)',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 9.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
