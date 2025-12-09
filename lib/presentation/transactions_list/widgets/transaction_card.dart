import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/user_settings_service.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';

/// Central category definition used by the card and the picker.
/// Color is not stored here because we are using a neutral color
/// for all icons (Option C).
class _CategoryDefinition {
  final String id;
  final String label;
  final String iconName;

  const _CategoryDefinition({
    required this.id,
    required this.label,
    required this.iconName,
  });
}

/// Single source of truth for all business_category enum values.
/// IDs must match Supabase enum values exactly.
const Map<String, _CategoryDefinition> _categoryDefinitions = {
  // Income
  'rev_sales': _CategoryDefinition(
    id: 'rev_sales',
    label: 'Sales revenue',
    iconName: 'trending_up',
  ),

  // Marketing
  'mkt_ads': _CategoryDefinition(
    id: 'mkt_ads',
    label: 'Marketing ads',
    iconName: 'campaign',
  ),
  'mkt_software': _CategoryDefinition(
    id: 'mkt_software',
    label: 'Marketing software',
    iconName: 'devices',
  ),
  'mkt_subs': _CategoryDefinition(
    id: 'mkt_subs',
    label: 'Marketing subscriptions',
    iconName: 'receipt_long',
  ),

  // Operations
  'ops_equipment': _CategoryDefinition(
    id: 'ops_equipment',
    label: 'Equipment',
    iconName: 'construction',
  ),
  'ops_supplies': _CategoryDefinition(
    id: 'ops_supplies',
    label: 'Supplies',
    iconName: 'inventory_2',
  ),
  'ops_rent': _CategoryDefinition(
    id: 'ops_rent',
    label: 'Rent',
    iconName: 'home_work',
  ),
  'ops_insurance': _CategoryDefinition(
    id: 'ops_insurance',
    label: 'Insurance',
    iconName: 'shield',
  ),
  'ops_taxes': _CategoryDefinition(
    id: 'ops_taxes',
    label: 'Taxes',
    iconName: 'request_quote',
  ),
  'ops_fees': _CategoryDefinition(
    id: 'ops_fees',
    label: 'Bank and service fees',
    iconName: 'receipt',
  ),

  // Professional services
  'pro_accounting': _CategoryDefinition(
    id: 'pro_accounting',
    label: 'Accounting and bookkeeping',
    iconName: 'calculate',
  ),
  'pro_contractors': _CategoryDefinition(
    id: 'pro_contractors',
    label: 'Freelancers and contractors',
    iconName: 'groups_2',
  ),

  // Travel
  'travel_general': _CategoryDefinition(
    id: 'travel_general',
    label: 'Travel',
    iconName: 'flight_takeoff',
  ),
  'travel_meals': _CategoryDefinition(
    id: 'travel_meals',
    label: 'Travel meals',
    iconName: 'restaurant',
  ),

  // People
  'people_salary': _CategoryDefinition(
    id: 'people_salary',
    label: 'Salary and wages',
    iconName: 'badge',
  ),
  'people_training': _CategoryDefinition(
    id: 'people_training',
    label: 'Training and education',
    iconName: 'school',
  ),

  // Other
  'other_expense': _CategoryDefinition(
    id: 'other_expense',
    label: 'Other expense',
    iconName: 'more_horiz',
  ),
  'other_refunds': _CategoryDefinition(
    id: 'other_refunds',
    label: 'Customer refunds',
    iconName: 'undo',
  ),
};

_CategoryDefinition _getDefinition(String id) {
  return _categoryDefinitions[id] ??
      _CategoryDefinition(
        id: id,
        label: id
            .split('_')
            .map(
              (w) => w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' '),
        iconName: 'category',
      );
}

class TransactionCard extends StatefulWidget {
  final TransactionRecord transaction;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onAddNote;
  final VoidCallback onMarkBusiness;
  final VoidCallback onShare;
  final ValueChanged<String> onCategoryChange;

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
    if (!mounted) return;
    setState(() {
      _currencySettings = settings;
    });
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final options = _categoryDefinitions.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final neutralIconColor =
        colorScheme.onSurface.withValues(alpha: 0.7);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: SingleChildScrollView(
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
                  color: neutralIconColor,
                  size: 24,
                ),
                title: const Text('Edit transaction'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'content_copy',
                  color: neutralIconColor,
                  size: 24,
                ),
                title: const Text('Duplicate transaction'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDuplicate();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'note_add',
                  color: neutralIconColor,
                  size: 24,
                ),
                title: const Text('Add note'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddNote();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'business_center',
                  color: neutralIconColor,
                  size: 24,
                ),
                title: const Text('Mark as business'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onMarkBusiness();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: neutralIconColor,
                  size: 24,
                ),
                title: const Text('Share'),
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
                  'Delete transaction',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.errorRed,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),
              SizedBox(height: 1.5.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Text(
                    'Change category',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                ),
              ),
              SizedBox(height: 0.5.h),
              _CategoryPicker(
                currentCategoryId: widget.transaction.category,
                options: options,
                iconColor: neutralIconColor,
                onCategorySelected: (id) {
                  Navigator.pop(context);
                  widget.onCategoryChange(id);
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    final t = widget.transaction;
    final def = _getDefinition(t.category);
    final isExpense = t.type == 'expense';

    final formattedAmount = IncoreNumberFormatter.formatAmountWithCurrency(
      t.amount.abs(),
      locale: _currencySettings!.locale,
      symbol: _currencySettings!.symbol,
    );

    final paymentMethodLabel =
        (t.paymentMethod == null || t.paymentMethod!.isNotEmpty == false)
            ? 'No method'
            : t.paymentMethod!;

    final neutralIconColor =
        colorScheme.onSurface.withValues(alpha: 0.7);
    final neutralBgColor =
        colorScheme.onSurface.withValues(alpha: 0.06);

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
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
            // Category icon (neutral color)
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: neutralBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: def.iconName,
                  color: neutralIconColor,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            // Description, category label, payment method
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      // no extra icon before label anymore
                      Text(
                        def.label,
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
                        paymentMethodLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount and client
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isExpense ? '- $formattedAmount' : formattedAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isExpense
                        ? AppTheme.errorRed
                        : AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                if (t.client != null && t.client!.isNotEmpty)
                  Text(
                    t.client!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String currentCategoryId;
  final List<_CategoryDefinition> options;
  final Color iconColor;
  final ValueChanged<String> onCategorySelected;

  const _CategoryPicker({
    required this.currentCategoryId,
    required this.options,
    required this.iconColor,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((def) {
        final isSelected = currentCategoryId == def.id;
        return ListTile(
          leading: CustomIconWidget(
            iconName: def.iconName,
            color: iconColor,
            size: 24,
          ),
          title: Text(def.label),
          trailing: isSelected ? const Icon(Icons.check) : null,
          onTap: () => onCategorySelected(def.id),
        );
      }).toList(),
    );
  }
}
