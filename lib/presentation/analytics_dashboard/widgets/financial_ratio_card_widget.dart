import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors_ext.dart';

/// Financial ratio card widget
class FinancialRatioCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final Color indicatorColor;
  final IconData icon;

  const FinancialRatioCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.indicatorColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowCard,
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
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: CustomIconWidget(
                  iconName: _getIconName(icon),
                  color: indicatorColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Tooltip(
                message: description,
                child: CustomIconWidget(
                  iconName: 'info_outline',
                  color: context.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.percent) return 'percent';
    if (icon == Icons.local_fire_department) return 'local_fire_department';
    if (icon == Icons.flight_takeoff) return 'flight_takeoff';
    return 'analytics';
  }
}
