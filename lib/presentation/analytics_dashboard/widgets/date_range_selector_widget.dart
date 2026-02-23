import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors_ext.dart';

/// Date range selector widget
class DateRangeSelectorWidget extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const DateRangeSelectorWidget({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ranges = ['Last 30 days', '3 months', '6 months', 'Year'];

    return Container(
      height: 4.5.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ranges.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final range = ranges[index];
          final isSelected = range == selectedRange;

          return InkWell(
            onTap: () => onRangeChanged(range),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: AnimatedContainer(
              duration: AppTheme.mediumDuration,
              curve: AppTheme.defaultCurve,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primary
                    : context.borderSubtle.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: isSelected
                      ? context.primary
                      : context.borderSubtle.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  range,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? context.surface
                        : context.textPrimary,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
