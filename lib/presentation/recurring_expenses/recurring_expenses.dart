import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/errors/app_error.dart';
import '../../core/errors/app_error_classifier.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/usage/limit_reached_exception.dart';
import '../../models/recurring_expense.dart';
import '../../services/auth_guard.dart';
import '../../services/recurring_expenses_repository.dart';
import '../../services/user_settings_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_error_widget.dart';
import './widgets/add_edit_recurring_expense_dialog.dart';
import './widgets/recurring_expense_card.dart';

/// Recurring Expenses Screen
/// Displays a list of recurring expenses with CRUD operations.
/// No calendar, no grouping, no projections.
/// Screen is accessed only from Dashboard → "Upcoming bills" CTA.
class RecurringExpenses extends StatefulWidget {
  const RecurringExpenses({super.key});

  @override
  State<RecurringExpenses> createState() => _RecurringExpensesState();
}

class _RecurringExpensesState extends State<RecurringExpenses> {
  final RecurringExpensesRepository _repository = RecurringExpensesRepository();
  final UserSettingsService _userSettingsService = UserSettingsService();

  List<RecurringExpense> _expenses = [];
  bool _isLoading = true;
  AppError? _loadError;

  UserCurrencySettings _currencySettings = const UserCurrencySettings(
    currencyCode: 'EUR',
    symbol: '€',
    locale: 'pt_PT',
  );

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings().then((_) {
      _loadRecurringExpenses();
    });
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      setState(() {
        _currencySettings = settings;
      });
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> _loadRecurringExpenses() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final expenses =
          await _repository.getRecurringExpensesForCurrentUser();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e, st) {
      AppLogger.e('Recurring expenses load error', error: e, stackTrace: st);
      final appError = AppErrorClassifier.classify(e, stackTrace: st);

      if (!mounted) return;

      // Route to auth error screen for auth failures
      if (appError.category == AppErrorCategory.auth) {
        AuthGuard.routeToErrorIfInvalid(context, reason: appError.debugReason);
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = appError;
      });
    }
  }

  Future<void> _handleAddExpense() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditRecurringExpenseDialog(),
    );

    if (result == true) {
      _loadRecurringExpenses();
    }
  }

  Future<void> _handleEditExpense(RecurringExpense expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditRecurringExpenseDialog(
        initialExpense: expense,
      ),
    );

    if (result == true) {
      _loadRecurringExpenses();
    }
  }

  Future<void> _handleToggleActive(RecurringExpense expense) async {
    try {
      if (expense.isActive) {
        await _repository.deactivateRecurringExpense(id: expense.id);
      } else {
        await _repository.reactivateRecurringExpense(id: expense.id);
      }
      _loadRecurringExpenses();
    } on LimitReachedException {
      // Paywall was shown, user did not upgrade
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showInfo(context, l10n.limitReachedRecurring);
    } catch (e, st) {
      AppLogger.e('Toggle recurring expense error', error: e, stackTrace: st);
      final appError = AppErrorClassifier.classify(e, stackTrace: st);

      if (!mounted) return;

      if (appError.category == AppErrorCategory.auth) {
        AuthGuard.routeToErrorIfInvalid(context, reason: appError.debugReason);
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showError(context, l10n.somethingWentWrong);
    }
  }

  Future<void> _handleDelete(RecurringExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

        return AlertDialog(
          title: Text(l10n.deleteConfirmTitle),
          content: Text(
            l10n.deleteConfirmMessage(expense.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _repository.deleteRecurringExpense(id: expense.id);
        _loadRecurringExpenses();
      } catch (e, st) {
        AppLogger.e('Delete recurring expense error', error: e, stackTrace: st);
        final appError = AppErrorClassifier.classify(e, stackTrace: st);

        if (!mounted) return;

        if (appError.category == AppErrorCategory.auth) {
          AuthGuard.routeToErrorIfInvalid(context, reason: appError.debugReason);
          return;
        }

        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showError(context, l10n.somethingWentWrong);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.canvasFrostedLight,
      appBar: AppBar(
        title: Text(l10n.recurringExpenses),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.canvasFrostedLight,
        foregroundColor: AppColors.slate900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.blue600,
              ),
            )
          : _loadError != null
              ? AppErrorWidget(
                  error: _loadError!,
                  displayMode: AppErrorDisplayMode.fullScreen,
                  onRetry: _loadRecurringExpenses,
                )
              : _expenses.isEmpty
                  ? _buildEmptyState(context, l10n)
                  : _buildExpensesList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddExpense,
        backgroundColor: AppColors.blue600,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: AppColors.slate400.withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.noRecurringExpenses,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.slate900,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.addRecurringExpensesHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate500,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _handleAddExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              ),
              child: Text(
                l10n.addRecurringExpense,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRecurringExpenses,
      color: AppColors.blue600,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return RecurringExpenseCard(
            expense: expense,
            locale: _currencySettings.locale,
            symbol: _currencySettings.symbol,
            currencyCode: _currencySettings.currencyCode,
            onEdit: () => _handleEditExpense(expense),
            onToggleActive: () => _handleToggleActive(expense),
            onDelete: () => _handleDelete(expense),
          );
        },
      ),
    );
  }
}
