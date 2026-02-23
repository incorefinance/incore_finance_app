import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_settings_service.dart';
import '../../theme/app_colors_ext.dart';

/// Currency selection screen - Second step of the onboarding flow.
/// User must select a currency before continuing (mandatory).
class OnboardingCurrencyScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingCurrencyScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<OnboardingCurrencyScreen> createState() =>
      _OnboardingCurrencyScreenState();
}

class _OnboardingCurrencyScreenState extends State<OnboardingCurrencyScreen> {
  final UserSettingsService _userSettingsService = UserSettingsService();

  String? _selectedCurrency;
  bool _isSaving = false;

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
  ];

  Future<void> _handleContinue() async {
    if (_selectedCurrency == null) return;

    setState(() => _isSaving = true);

    try {
      await _userSettingsService.saveCurrencyCode(_selectedCurrency!);
      widget.onContinue();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save currency. Please try again.'),
          ),
        );
      }
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
                'Select your currency',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'This will be used for all amounts in the app.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.slate500,
                ),
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: ListView.separated(
                  itemCount: _currencies.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    return _buildCurrencyOption(
                      currency: currency,
                      theme: theme,
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedCurrency != null && !_isSaving ? _handleContinue : null,
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
                        : const Text('Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyOption({
    required Map<String, String> currency,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedCurrency == currency['code'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCurrency = currency['code'];
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? context.blue600
                  : context.borderGlass60,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: context.blue50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    currency['symbol']!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: context.blue600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency['code']!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      currency['name']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  size: 6.w,
                  color: context.blue600,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
