import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/user_settings_service.dart';
import '../../../utils/number_formatter.dart';

/// Transaction card widget with swipe actions
class TransactionCard extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onAddNote;
  final VoidCallback onMarkBusiness;
  final VoidCallback onShare;
  final Function(String) onCategoryChange;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onAddNote,
    required this.onMarkBusiness,
    required this.onShare,
    required this.onCategoryChange,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  final UserSettingsService _settingsService = UserSettingsService();
  UserCurrencySettings? _currencySettings;

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings();
  }

  Future<void> _loadCurrencySettings() async {
    final settings = await _settingsService.getCurrencySettings();
    if (mounted) {
      setState(() {
        _currencySettings = settings;
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFef4444);
      case 'transport':
        return const Color(0xFF3b82f6);
      case 'shopping':
        return const Color(0xFF8b5cf6);
      case 'entertainment':
        return const Color(0xFFec4899);
      case 'utilities':
        return const Color(0xFF10b981);
      case 'income':
        return const Color(0xFF22c55e);
      default:
        return const Color(0xFF6b7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.lightbulb;
      case 'income':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.neutralGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Edit Transaction'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                widget.onDuplicate();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'note_add',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.pop(context);
                widget.onAddNote();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'business_center',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Mark as Business Expense'),
              onTap: () {
                Navigator.pop(context);
                widget.onMarkBusiness();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Share Receipt'),
              onTap: () {
                Navigator.pop(context);
                widget.onShare();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorRed,
                size: 24,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showCategoryChangeSheet(BuildContext context) {
    final categories = [
      'Food',
      'Transport',
      'Shopping',
      'Entertainment',
      'Utilities',
      'Income',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.neutralGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Text(
                'Change Category',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ),
            ...categories.map(
              (category) => ListTile(
                leading: CustomIconWidget(
                  iconName: _getCategoryIcon(category).codePoint.toString(),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
                title: Text(category),
                onTap: () {
                  Navigator.pop(context);
                  widget.onCategoryChange(category);
                },
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If currency settings not loaded yet, show loading indicator
    if (_currencySettings == null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final amount = widget.transaction['amount'] as double;
    final category = widget.transaction['category'] as String;
    final categoryColor = _getCategoryColor(category);
    final isExpense = widget.transaction['type'] == 'expense';

    // Format amount with user's currency settings
    final formatted = IncoreNumberFormatter.formatAmountWithCurrency(
      amount.abs(),
      locale: _currencySettings!.locale,
      symbol: _currencySettings!.symbol,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(widget.transaction['category'] as String),
              color: categoryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transaction['description'] as String,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'category',
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      widget.transaction['category'] as String,
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'payment',
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      widget.transaction['payment_method'] as String,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isExpense ? '- $formatted' : formatted,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isExpense ? AppTheme.errorRed : AppTheme.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.transaction['client'] != null) ...[
                SizedBox(height: 0.5.h),
                Text(
                  widget.transaction['client'] as String,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
