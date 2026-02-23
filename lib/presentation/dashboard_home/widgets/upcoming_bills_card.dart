import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../models/recurring_expense.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../theme/app_theme.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceGlass80,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
              border: Border.all(
                color: context.borderGlass60,
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
                      color: context.slate400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.upcomingBills,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: context.slate500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (bills.isEmpty)
                  _buildEmptyState(context, theme, l10n)
                else
                  _buildBillsList(context, theme, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addRecurringExpensesHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.slate500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onAddBill,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.blue50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: context.blue600.withValues(alpha: 0.2),
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
                        color: context.blue600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.addBill,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: context.blue600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: onManageBills,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surfaceGlass80,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: context.blue600.withValues(alpha: 0.3),
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
                        color: context.blue600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.manageBills,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: context.blue600,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.blue50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: context.blue600.withValues(alpha: 0.2),
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
                        color: context.blue600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.addBill,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: context.blue600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: onManageBills,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surfaceGlass80,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: context.blue600.withValues(alpha: 0.3),
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
                        color: context.blue600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.manageBills,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: context.blue600,
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
        const SizedBox(height: 16),
        ...billsToShow.map((bill) => _buildBillItem(
              context,
              theme,
              bill,
              now,
              l10n,
            )),
        if (bills.length > _maxBillsToShow) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onManageBills,
            child: Text(
              l10n.viewAllRecurringExpenses(bills.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.blue600,
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
    RecurringExpense bill,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final nextDue = _computeNextDueDate(bill.dueDay, now);
    final daysUntil =
        nextDue.difference(DateTime(now.year, now.month, now.day)).inDays;

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
      padding: const EdgeInsets.only(bottom: 12),
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
                    color: context.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dueDateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.slate500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedAmount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.slate900,
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
