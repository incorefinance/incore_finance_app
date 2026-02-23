import 'package:flutter/material.dart';
import 'package:incore_finance/theme/app_colors_ext.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../core/app_export.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/app_error_classifier.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/usage/limit_reached_exception.dart';
import '../../services/auth_guard.dart';
import '../../utils/number_formatter.dart';
import '../../utils/snackbar_helper.dart';
import './widgets/amount_input_widget.dart';
import './widgets/category_selector_widget.dart';
import './widgets/payment_method_selector.dart';
import './widgets/quick_templates_widget.dart';
import './widgets/transaction_type_toggle.dart';

/// Add Transaction Screen
/// Enables quick financial entry through modal presentation with stack navigation
class AddTransaction extends StatefulWidget {
  const AddTransaction({
    super.key,
    this.initialTransaction,
  });

  final TransactionRecord? initialTransaction;

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();

  // Repository
  final TransactionsRepository _repository = TransactionsRepository();
  final UserSettingsService _settingsService = UserSettingsService();

  // State variables
  bool _isIncome = false;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  String? _selectedTemplate; // Track selected quick template
  DateTime _selectedDate = DateTime.now();
  bool _isSaveEnabled = false;
  bool _isSaving = false;
  bool get _isEditing => widget.initialTransaction != null;

  // Currency settings
  String _locale = 'pt_PT'; // Default locale
  String _currencySymbol = '€'; // Default symbol

  // Add this getter for transaction type
  String get _transactionType => _isIncome ? 'income' : 'expense';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _loadUserSettings();
    _prefillIfEditing();
  }

  /// Load user currency settings
  Future<void> _loadUserSettings() async {
    try {
      final settings = await _settingsService.getCurrencySettings();
      setState(() {
        _locale = settings.locale;
        _currencySymbol = settings.symbol;
      });
    } catch (e) {
      // Use defaults if loading fails
      setState(() {
        _locale = 'pt_PT';
        _currencySymbol = '€';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  void _prefillIfEditing() {
    final t = widget.initialTransaction;
    if (t == null) return;

    _isIncome = t.type == 'income';
    _selectedCategory = t.category;
    _selectedPaymentMethod = t.paymentMethod;
    _selectedDate = t.date;

    _descriptionController.text = t.description;
    _clientController.text = t.client ?? '';

    _amountController.text = IncoreNumberFormatter.formatAmount(
      t.amount,
      locale: _locale,
    );

    _validateForm();
  }

  void _validateForm() {
    setState(() {
      _isSaveEnabled =
          _amountController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _selectedCategory != null &&
          _selectedPaymentMethod != null;
    });
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate all required fields before proceeding
    if (_amountController.text.isEmpty) {
      SnackbarHelper.showError(context, l10n.pleaseEnterAmount);
      return;
    }

    if (_descriptionController.text.isEmpty) {
      SnackbarHelper.showError(context, l10n.pleaseEnterDescription);
      return;
    }

    if (_selectedCategory == null) {
      SnackbarHelper.showError(context, l10n.pleaseSelectCategory);
      return;
    }

    if (_selectedPaymentMethod == null) {
      SnackbarHelper.showError(context, l10n.pleaseSelectPaymentMethod);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parse amount using IncoreNumberFormatter with user's locale
      final amount = IncoreNumberFormatter.parseAmount(
        _amountController.text,
        locale: _locale,
      );

      // Validate parsed amount
      if (amount == null || amount <= 0) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(
          context,
          l10n.validAmountError,
        );
        return;
      }

      // Save to database
      final client =
          _clientController.text.trim().isNotEmpty
              ? _clientController.text.trim()
              : null;

      if (_isEditing) {
        await _repository.updateTransaction(
          transactionId: widget.initialTransaction!.id,
          amount: amount,
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          type: _transactionType,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod!,
          client: client,
        );
      } else {
        await _repository.addTransaction(
          amount: amount,
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          type: _transactionType,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod!,
          client: client,
        );
      }


      if (mounted) {
        setState(() => _isSaving = false);

        // Show success message
       SnackbarHelper.showSuccess(
          context,
          _isEditing ? l10n.transactionUpdatedSuccess : l10n.transactionAddedSuccess,
        );

        // Navigate back and return true to indicate success
        Navigator.of(context).pop(true);
      }
    } on LimitReachedException {
      // Paywall was shown, user did not upgrade
      // Stay on screen so user can try again or go back
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarHelper.showInfo(context, l10n.limitReachedMonthly);
    } catch (e, st) {
      AppLogger.e('Error saving transaction', error: e, stackTrace: st);
      final appError = AppErrorClassifier.classify(e, stackTrace: st);

      if (!mounted) return;

      setState(() => _isSaving = false);

      // Route to auth error screen for auth failures
      if (appError.category == AppErrorCategory.auth) {
        AuthGuard.routeToErrorIfInvalid(context, reason: appError.debugReason);
        return;
      }

      // For network errors, show snackbar with retry action
      if (appError.category == AppErrorCategory.network) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.networkErrorMessage),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: _handleSave,
            ),
          ),
        );
        return;
      }

      // For unknown errors, show generic failure message
      SnackbarHelper.showError(
        context,
        l10n.failedToAddTransaction,
      );
    }
  }

  void _handleTemplateSelection(
    String description,
    String category,
    double amount,
  ) {
    setState(() {
      _selectedTemplate = description; // Track selected template
      _descriptionController.text = description;
      // Category is no longer auto-assigned from templates
      // User must select category manually from the Category Selector
      // _selectedCategory = category; // REMOVED - prevents invalid categories
      _amountController.text = amount.toStringAsFixed(2);
    });
    _validateForm();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.blue600,
              onPrimary: Colors.white,
              surface: context.canvasFrosted,
              onSurface: context.slate900,
              surfaceContainerHighest: context.surfaceGlass80,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: context.canvasFrosted,
              headerBackgroundColor: context.surfaceGlass80,
              headerForegroundColor: context.slate900,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return context.slate400;
                }
                return context.slate900;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return context.blue600;
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return context.blue600;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return context.blue600;
                }
                return Colors.transparent;
              }),
              todayBorder: BorderSide(color: context.blue600, width: 1),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return context.slate900;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return context.blue600;
                }
                return Colors.transparent;
              }),
              weekdayStyle: TextStyle(
                color: context.slate500,
                fontWeight: FontWeight.w500,
              ),
              dayStyle: TextStyle(
                color: context.slate900,
                fontWeight: FontWeight.w400,
              ),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
              ),
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(context.slate600),
              ),
              confirmButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(context.blue600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.canvasFrosted,
      body: SafeArea(
        child: Column(
          children: [
            // Drag indicator
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: context.slate400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _isSaving ? context.slate400 : context.slate600,
                      ),
                    ),
                  ),
                  Text(
                    _isEditing ? l10n.editTransaction : l10n.addTransaction,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.slate900,
                    ),
                  ),
                  _isSaving
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      )
                      : TextButton(
                        onPressed:
                            _isSaveEnabled && !_isSaving ? _handleSave : null,
                        child: Text(
                          l10n.save,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                _isSaveEnabled && !_isSaving
                                    ? context.blue600
                                    : context.slate400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: context.dividerGlass60,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Input
                    AmountInputWidget(
                      controller: _amountController,
                      currencySymbol: _currencySymbol,
                      locale: _locale,
                      onChanged: (value) => _validateForm(),
                      isIncome: _isIncome,
                    ),

                    SizedBox(height: 3.h),

                    // Transaction Type Toggle
                    TransactionTypeToggle(
                      isIncome: _isIncome,
                      onToggle: (isIncome) {
                        setState(() {
                          _isIncome = isIncome;
                          _selectedCategory = null;
                          _selectedTemplate = null; // Clear template when type changes
                        });
                        _validateForm();
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        labelStyle: TextStyle(color: context.slate500),
                        hintText: l10n.enterDescription,
                        hintStyle: TextStyle(color: context.slate400),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'description',
                            color: context.slate400,
                            size: 24,
                          ),
                        ),
                        filled: true,
                        fillColor: context.surfaceGlass80,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: context.borderGlass60),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: context.borderGlass60),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: context.blue600.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      style: TextStyle(color: context.slate900),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    SizedBox(height: 3.h),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceGlass80,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: context.borderGlass60,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'calendar_today',
                              color: context.slate400,
                              size: 24,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.date,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: context.slate500,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_selectedDate),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: context.slate900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CustomIconWidget(
                              iconName: 'chevron_right',
                              color: context.slate400,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Category Selector
                    CategorySelectorWidget(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _validateForm();
                      },
                      isIncome: _isIncome,
                    ),

                    SizedBox(height: 3.h),

                    // Payment Method Selector
                    PaymentMethodSelector(
                      selectedMethod: _selectedPaymentMethod,
                      onMethodSelected: (method) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                        _validateForm();
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Client Field (Optional)
                    TextField(
                      controller: _clientController,
                      decoration: InputDecoration(
                        labelText: l10n.optionalClient,
                        labelStyle: TextStyle(color: context.slate500),
                        hintText: l10n.enterClientHint,
                        hintStyle: TextStyle(color: context.slate400),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'person',
                            color: context.slate400,
                            size: 24,
                          ),
                        ),
                        filled: true,
                        fillColor: context.surfaceGlass80,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: context.borderGlass60),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: context.borderGlass60),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: context.blue600.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      style: TextStyle(color: context.slate900),
                      textCapitalization: TextCapitalization.words,
                    ),

                    SizedBox(height: 3.h),

                    // Quick Templates
                    QuickTemplatesWidget(
                      onTemplateSelected: _handleTemplateSelection,
                      isIncome: _isIncome,
                      locale: _locale,
                      selectedTemplate: _selectedTemplate,
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
