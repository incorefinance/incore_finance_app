import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/recurring_expense.dart';
import '../../../services/recurring_expenses_repository.dart';
import '../../../services/user_settings_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/snackbar_helper.dart';

/// Add/Edit Recurring Expense Dialog
/// Handles both create and update operations with form validation.
class AddEditRecurringExpenseDialog extends StatefulWidget {
  final RecurringExpense? initialExpense;

  const AddEditRecurringExpenseDialog({
    super.key,
    this.initialExpense,
  });

  @override
  State<AddEditRecurringExpenseDialog> createState() =>
      _AddEditRecurringExpenseDialogState();
}

class _AddEditRecurringExpenseDialogState
    extends State<AddEditRecurringExpenseDialog> {
  final RecurringExpensesRepository _repository = RecurringExpensesRepository();
  final UserSettingsService _userSettingsService = UserSettingsService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  late TextEditingController _dueDayController;

  String _locale = 'pt_PT';
  bool _isSaving = false;
  bool _isSaveEnabled = false;

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    _dueDayController =
        TextEditingController(text: _isEditing ? '${widget.initialExpense!.dueDay}' : '1');
    _nameController.addListener(_validateForm);
    _amountController.addListener(_validateForm);
    _dueDayController.addListener(_validateForm);
    _loadUserSettings();
    _prefillIfEditing();
  }

  Future<void> _loadUserSettings() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      setState(() {
        _locale = settings.locale;
      });
    } catch (_) {
      setState(() {
        _locale = 'pt_PT';
      });
    }
  }

  void _prefillIfEditing() {
    final expense = widget.initialExpense;
    if (expense == null) return;

    _nameController.text = expense.name;
    _amountController.text = IncoreNumberFormatter.formatAmount(
      expense.amount,
      locale: _locale,
    );
    _dueDayController.text = '${expense.dueDay}';
  }

  void _validateForm() {
    setState(() {
      _isSaveEnabled = _nameController.text.trim().isNotEmpty &&
          _amountController.text.isNotEmpty &&
          _dueDayController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final amountText = _amountController.text;
    final dueDayText = _dueDayController.text.trim();

    // Validate amount
    final amount = IncoreNumberFormatter.parseAmount(
      amountText,
      locale: _locale,
    );
    if (amount == null || amount <= 0) {
      SnackbarHelper.showError(
        context,
        l10n.validAmountError,
      );
      return;
    }

    // Validate due day
    final dueDay = int.tryParse(dueDayText);
    if (dueDay == null || dueDay < 1 || dueDay > 31) {
      SnackbarHelper.showError(
        context,
        l10n.dueDayRangeError,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _repository.updateRecurringExpense(
          id: widget.initialExpense!.id,
          name: name,
          amount: amount,
          dueDay: dueDay,
          isActive: widget.initialExpense!.isActive,
        );
      } else {
        await _repository.addRecurringExpense(
          name: name,
          amount: amount,
          dueDay: dueDay,
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showSuccess(
          context,
          _isEditing
              ? l10n.recurringExpenseUpdated
              : l10n.recurringExpenseAdded,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final errorMessage = e is StateError
            ? e.message
            : l10n.failedToSaveRecurringExpense;
        SnackbarHelper.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(_isEditing ? l10n.editRecurringExpense : l10n.addRecurringExpense),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),
            // Name field
            _buildTextField(
              controller: _nameController,
              label: l10n.name,
              hint: l10n.namePlaceholder,
              keyboardType: TextInputType.text,
              theme: theme,
            ),
            SizedBox(height: 1.5.h),
            // Amount field
            _buildTextField(
              controller: _amountController,
              label: l10n.amount,
              hint: l10n.amountPlaceholder,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              theme: theme,
            ),
            SizedBox(height: 1.5.h),
            // Due day field
            _buildTextField(
              controller: _dueDayController,
              label: l10n.dueDay,
              hint: l10n.dueDayHint,
              keyboardType: TextInputType.number,
              theme: theme,
            ),
            SizedBox(height: 0.5.h),
            Text(
              l10n.dueDayHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaveEnabled && !_isSaving ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isSaving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditing ? l10n.update : l10n.add,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.2.h,
            ),
          ),
        ),
      ],
    );
  }
}
