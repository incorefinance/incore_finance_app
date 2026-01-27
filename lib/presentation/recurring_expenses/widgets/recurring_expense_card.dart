import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/recurring_expense.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/number_formatter.dart';

/// Recurring Expense Card - Displays a single recurring expense item
class RecurringExpenseCard extends StatelessWidget {
  final RecurringExpense expense;
  final String locale;
  final String symbol;
  final String currencyCode;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const RecurringExpenseCard({
    super.key,
    required this.expense,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formatted = IncoreNumberFormatter.formatMoney(
      expense.amount,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    // Muted style for inactive items
    final opacity = expense.isActive ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.2.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          'Due on day ${expense.dueDay}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    formatted,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.2.h),
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 0.8.w,
                      children: [
                        // Edit button
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onPressed: onEdit,
                          color: AppColors.primary,
                        ),
                        // Toggle active/inactive button
                        _ActionButton(
                          icon: expense.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          label: expense.isActive ? 'Deactivate' : 'Reactivate',
                          onPressed: onToggleActive,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  // Delete button (secondary)
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: onDelete,
                    color: AppColors.error,
                  ),
                ],
              ),
              // Active/Inactive status badge
              if (!expense.isActive)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      'Inactive',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact action button for card actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(right: 0.4.w),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.4.h),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
