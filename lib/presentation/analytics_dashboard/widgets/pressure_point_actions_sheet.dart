import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import 'package:incore_finance/l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../models/recurring_expense.dart';

/// Bottom sheet offering one-tap mitigation actions for pressure point alerts.
///
/// Actions:
/// - "Review bills" — navigates to recurring expenses screen.
/// - "Pause non essential" — shows active expenses with checkboxes;
///   user selects which to deactivate, then taps "Pause selected".
class PressurePointActionsSheet extends StatefulWidget {
  final List<RecurringExpense> activeExpenses;
  final String currencyLocale;
  final String currencySymbol;
  final VoidCallback onReviewBills;
  final Future<void> Function(List<String> expenseIds) onPauseExpenses;

  const PressurePointActionsSheet({
    super.key,
    required this.activeExpenses,
    required this.currencyLocale,
    required this.currencySymbol,
    required this.onReviewBills,
    required this.onPauseExpenses,
  });

  @override
  State<PressurePointActionsSheet> createState() =>
      _PressurePointActionsSheetState();
}

class _PressurePointActionsSheetState extends State<PressurePointActionsSheet> {
  final Set<String> _selectedIds = {};
  bool _isPausing = false;

  Future<void> _handlePause() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pressurePointNoBillsSelected)),
      );
      return;
    }

    setState(() => _isPausing = true);

    try {
      await widget.onPauseExpenses(_selectedIds.toList());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pressurePointPausedSnack),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPausing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pressurePointPauseErrorSnack)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final currency = NumberFormat.currency(
      locale: widget.currencyLocale,
      symbol: widget.currencySymbol,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.pressurePointReducePressureTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),

              SizedBox(height: 0.5.h),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.pressurePointReducePressureBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // "Review bills" action row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onReviewBills();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.pressurePointReviewBills,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: const Divider(height: 1),
              ),

              SizedBox(height: 1.5.h),

              // "Pause non essential" label
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.pressurePointPauseNonEssential,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 0.5.h),

              // Expense list with checkboxes
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  itemCount: widget.activeExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = widget.activeExpenses[index];
                    final isChecked = _selectedIds.contains(expense.id);
                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: colorScheme.primary,
                      onChanged: _isPausing
                          ? null
                          : (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedIds.add(expense.id);
                                } else {
                                  _selectedIds.remove(expense.id);
                                }
                              });
                            },
                      title: Text(
                        expense.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        '${currency.format(expense.amount.abs())} · day ${expense.dueDay}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),

              SizedBox(height: 1.5.h),

              // "Pause selected" button
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty || _isPausing
                        ? null
                        : _handlePause,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 5.h),
                    ),
                    child: _isPausing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(l10n.pressurePointPauseSelected),
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
