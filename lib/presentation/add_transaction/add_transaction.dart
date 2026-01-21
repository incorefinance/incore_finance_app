import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:incore_finance/models/transaction_record.dart';

import '../../core/app_export.dart';
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
    // Validate all required fields before proceeding
    if (_amountController.text.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter an amount');
      return;
    }

    if (_descriptionController.text.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter a description');
      return;
    }

    if (_selectedCategory == null) {
      SnackbarHelper.showError(context, 'Please select a category');
      return;
    }

    if (_selectedPaymentMethod == null) {
      SnackbarHelper.showError(context, 'Please select a payment method');
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
          'Please enter a valid amount greater than zero',
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
          _isEditing ? 'Transaction updated successfully!' : 'Transaction added successfully!',
        );

        // Navigate back and return true to indicate success
        Navigator.of(context).pop(true);
      }
       } catch (e, stackTrace) {
      // TEMPORARY DEBUG LOGGING – to understand why Supabase is failing
      // This will print to your terminal / VS Code debug console.
      // Do NOT leave prints like this in production, but it is perfect for Sprint 01 debugging.
      // -----------------------------------------------------------
      // ignore: avoid_print
      print('=== ERROR ADDING TRANSACTION ===');
      // ignore: avoid_print
      print('Error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      // -----------------------------------------------------------

      if (mounted) {
        setState(() => _isSaving = false);

        SnackbarHelper.showError(
          context,
          'Failed to add transaction. Please try again.',
        );
      }
    }
  }

  void _handleTemplateSelection(
    String description,
    String category,
    double amount,
  ) {
    setState(() {
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.accentGold),
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Drag indicator
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
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
                      'Cancel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            _isSaving
                                ? colorScheme.onSurface.withValues(alpha: 0.3)
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Text(
                    'Add Transaction',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _isSaving
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentGold,
                          ),
                        ),
                      )
                      : TextButton(
                        onPressed:
                            _isSaveEnabled && !_isSaving ? _handleSave : null,
                        child: Text(
                          'Save',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                _isSaveEnabled && !_isSaving
                                    ? AppTheme.accentGold
                                    : colorScheme.onSurface.withValues(
                                      alpha: 0.3,
                                    ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
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
                        });
                        _validateForm();
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter transaction description',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'description',
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
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
                        labelText: 'Client (Optional)',
                        hintText: 'Enter client name',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'person',
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),

                    SizedBox(height: 3.h),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'calendar_today',
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              size: 24,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_selectedDate),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CustomIconWidget(
                              iconName: 'chevron_right',
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Quick Templates
                    QuickTemplatesWidget(
                      onTemplateSelected: _handleTemplateSelection,
                      isIncome: _isIncome,
                      locale: _locale,
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
