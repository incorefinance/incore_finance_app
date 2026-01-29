import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';

/// Upcoming Bills Placeholder - Setup-required block for recurring expenses.
/// Displays a calm, neutral message prompting user to set up recurring expenses.
/// CTA navigates to Recurring Expenses screen.
class UpcomingBillsPlaceholder extends StatelessWidget {
  const UpcomingBillsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                l10n.upcomingBills,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            l10n.addRecurringExpensesHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          // CTA button - navigates to Recurring Expenses screen
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/recurring-expenses');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    l10n.setUpRecurringExpenses,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
}
