import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../models/recurring_expense.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/number_formatter.dart';

/// Upcoming Bills Card - Shows upcoming recurring expenses.
/// Displays bills sorted by next due date, or a setup prompt if none exist.
class UpcomingBillsCard extends StatelessWidget {
  final List<RecurringExpense> bills;
  final String locale;
  final String symbol;
  final String currencyCode;
  final VoidCallback? onAddBill;
  final VoidCallback? onManageBills;

  /// Maximum number of bills to display
  static const int _maxBillsToShow = 3;

  const UpcomingBillsCard({
    super.key,
    required this.bills,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.onAddBill,
    this.onManageBills,
  });

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
          if (bills.isEmpty)
            _buildEmptyState(context, theme, colorScheme, l10n)
          else
            _buildBillsList(context, theme, colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addRecurringExpensesHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onAddBill,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        l10n.addBill,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: GestureDetector(
                onTap: onManageBills,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        l10n.manageBills,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillsList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final billsToShow = bills.take(_maxBillsToShow).toList();

    return Column(
      children: [
        // Add and Manage buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onAddBill,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        l10n.addBill,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: GestureDetector(
                onTap: onManageBills,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        l10n.manageBills,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        ...billsToShow.map((bill) => _buildBillItem(
              context,
              theme,
              colorScheme,
              bill,
              now,
              l10n,
            )),
        if (bills.length > _maxBillsToShow) ...[
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: onManageBills,
            child: Text(
              l10n.viewAllRecurringExpenses(bills.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    RecurringExpense bill,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final nextDue = _computeNextDueDate(bill.dueDay, now);
    final daysUntil = nextDue.difference(DateTime(now.year, now.month, now.day)).inDays;

    final formattedAmount = IncoreNumberFormatter.formatMoney(
      bill.amount,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    String dueDateText;
    if (daysUntil == 0) {
      dueDateText = l10n.dueToday;
    } else if (daysUntil == 1) {
      dueDateText = l10n.dueTomorrow;
    } else if (daysUntil <= 7) {
      dueDateText = l10n.dueInDays(daysUntil);
    } else {
      dueDateText = l10n.dueOnDay(nextDue.day, nextDue.month);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.3.h),
                Text(
                  dueDateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: daysUntil <= 3
                        ? AppColors.expense
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedAmount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Computes the next due date for a given due day.
  DateTime _computeNextDueDate(int dueDay, DateTime now) {
    final lastDayThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDayThisMonth =
        dueDay > lastDayThisMonth ? lastDayThisMonth : dueDay;
    final thisMonthDue = DateTime(now.year, now.month, clampedDayThisMonth);

    if (thisMonthDue.isAfter(now) ||
        (thisMonthDue.year == now.year &&
            thisMonthDue.month == now.month &&
            thisMonthDue.day == now.day)) {
      return thisMonthDue;
    }

    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final lastDayNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final clampedDayNextMonth =
        dueDay > lastDayNextMonth ? lastDayNextMonth : dueDay;

    return DateTime(nextYear, nextMonth, clampedDayNextMonth);
  }
}
