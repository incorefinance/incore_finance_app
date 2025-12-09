import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Toggle widget for switching between Income and Expense
class TransactionTypeToggle extends StatelessWidget {
  final bool isIncome;
  final Function(bool) onToggle;

  const TransactionTypeToggle({
    super.key,
    required this.isIncome,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(0.5.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              context: context,
              label: 'Income',
              icon: 'arrow_downward',
              isSelected: isIncome,
              color: AppTheme.successGreen,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(true);
              },
            ),
          ),
          SizedBox(width: 1.w),
          Expanded(
            child: _buildToggleButton(
              context: context,
              label: 'Expense',
              icon: 'arrow_upward',
              isSelected: !isIncome,
              color: AppTheme.errorRed,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required String icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: icon,
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 18,
              ),
              SizedBox(width: 1.w),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}