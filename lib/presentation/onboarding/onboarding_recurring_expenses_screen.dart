import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/recurring_expense.dart';
import '../../services/recurring_expenses_repository.dart';
import '../../services/user_settings_service.dart';
import '../../theme/app_colors_ext.dart';
import '../../utils/number_formatter.dart';
import '../recurring_expenses/widgets/add_edit_recurring_expense_dialog.dart';

/// Recurring expenses screen - Fourth step of the onboarding flow.
/// User can optionally add recurring expenses using the existing dialog.
class OnboardingRecurringExpensesScreen extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const OnboardingRecurringExpensesScreen({
    super.key,
    required this.onDone,
    required this.onSkip,
  });

  @override
  State<OnboardingRecurringExpensesScreen> createState() =>
      _OnboardingRecurringExpensesScreenState();
}

class _OnboardingRecurringExpensesScreenState
    extends State<OnboardingRecurringExpensesScreen> {
  final RecurringExpensesRepository _repository = RecurringExpensesRepository();
  final UserSettingsService _userSettingsService = UserSettingsService();

  List<RecurringExpense> _expenses = [];
  bool _isLoading = true;
  String _locale = 'pt_PT';
  String _currencyCode = 'EUR';
  String _currencySymbol = '€';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      final expenses = await _repository.getRecurringExpensesForCurrentUser();

      if (mounted) {
        setState(() {
          _locale = settings.locale;
          _currencyCode = settings.currencyCode;
          _currencySymbol = settings.symbol;
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddExpenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditRecurringExpenseDialog(),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: context.canvasFrosted,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.screenHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Text(
                'Add bills you pay every month',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'This helps track upcoming expenses.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.slate500,
                ),
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildExpensesList(theme, colorScheme),
              ),
              _buildActionButtons(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList(ThemeData theme, ColorScheme colorScheme) {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'receipt_long',
              size: 15.w,
              color: context.slate400,
            ),
            SizedBox(height: 2.h),
            Text(
              'No recurring expenses yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.slate500,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Add expenses like rent, utilities, or subscriptions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.slate400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _expenses.length,
      separatorBuilder: (context, index) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return _buildExpenseCard(expense, theme, colorScheme);
      },
    );
  }

  Widget _buildExpenseCard(
    RecurringExpense expense,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.borderGlass60,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Due day ${expense.dueDay}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.slate500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            IncoreNumberFormatter.formatMoney(
              expense.amount,
              locale: _locale,
              currencyCode: _currencyCode,
              symbol: _currencySymbol,
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              if (_expenses.isEmpty) ...[
                Expanded(
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: const Text('Skip for now'),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    child: const Text('Done'),
                  ),
                ),
              ],
            ],
          ),
          if (_expenses.isNotEmpty) ...[
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Add more later'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
