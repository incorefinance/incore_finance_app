import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Chart section widget for displaying different chart types
class ChartSectionWidget extends StatelessWidget {
  final String title;
  final Widget chart;
  final String? subtitle;

  const ChartSectionWidget({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 1.h),
            Text(
              subtitle!,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          SizedBox(height: 3.h),
          SizedBox(
            height: 30.h,
            child: chart,
          ),
          SizedBox(height: 2.5.h),
        ],
      ),
    );
  }
}
