import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_settings_service.dart';
import '../../services/user_financial_baseline_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/number_formatter.dart';

/// Starting balance screen - Third step of the onboarding flow.
/// User can optionally set their current cash position.
class OnboardingStartingBalanceScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingStartingBalanceScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingStartingBalanceScreen> createState() =>
      _OnboardingStartingBalanceScreenState();
}

class _OnboardingStartingBalanceScreenState
    extends State<OnboardingStartingBalanceScreen> {
  final UserSettingsService _userSettingsService = UserSettingsService();
  final UserFinancialBaselineRepository _baselineRepository =
      UserFinancialBaselineRepository();
  final TextEditingController _amountController = TextEditingController();

  String _locale = 'pt_PT';
  String _currencySymbol = '€';
  bool _isSaving = false;
  bool _isNegative = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      setState(() {
        _locale = settings.locale;
        _currencySymbol = settings.symbol;
      });
    } catch (_) {
      // Use defaults
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndContinue() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      widget.onSkip();
      return;
    }

    final parsedAmount = IncoreNumberFormatter.parseAmount(
      amountText,
      locale: _locale,
    );

    if (parsedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
        ),
      );
      return;
    }

    final finalAmount = _isNegative ? -parsedAmount.abs() : parsedAmount.abs();

    setState(() => _isSaving = true);

    try {
      await _baselineRepository.upsertStartingBalance(finalAmount);
      widget.onContinue();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final errorMessage = e is StateError
            ? e.message
            : 'Failed to save starting balance. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.canvasFrostedLight,
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
                'How much cash do you have right now?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'This helps show an accurate cash position. You can skip this and add it later.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate500,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  _buildSignToggle(theme, colorScheme),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixText: '$_currencySymbol ',
                        prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                _isNegative
                    ? 'Negative balance (you owe money)'
                    : 'Positive balance (you have money)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.slate400,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveAndContinue,
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
                        : const Text('Save and continue'),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSaving ? null : widget.onSkip,
                    child: const Text('Skip for now'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGlass60Light),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSignButton(
            label: '+',
            isSelected: !_isNegative,
            onTap: () => setState(() => _isNegative = false),
            theme: theme,
            colorScheme: colorScheme,
            isLeft: true,
          ),
          _buildSignButton(
            label: '-',
            isSelected: _isNegative,
            onTap: () => setState(() => _isNegative = true),
            theme: theme,
            colorScheme: colorScheme,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSignButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isLeft,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? Radius.circular(AppTheme.radiusMedium - 1) : Radius.zero,
        right: !isLeft ? Radius.circular(AppTheme.radiusMedium - 1) : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueBg50 : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left:
                isLeft ? Radius.circular(AppTheme.radiusMedium - 1) : Radius.zero,
            right: !isLeft
                ? Radius.circular(AppTheme.radiusMedium - 1)
                : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.blue600 : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}
