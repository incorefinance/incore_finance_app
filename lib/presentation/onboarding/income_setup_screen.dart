import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/profile/user_income_repository.dart';
import '../../domain/onboarding/income_type.dart';
import '../../l10n/app_localizations.dart';

/// Income setup screen - Part of the onboarding flow.
/// User must select an income type before continuing (mandatory).
/// Monthly estimate is optional.
class IncomeSetupScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const IncomeSetupScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<IncomeSetupScreen> createState() => _IncomeSetupScreenState();
}

class _IncomeSetupScreenState extends State<IncomeSetupScreen> {
  final UserIncomeRepository _incomeRepository = UserIncomeRepository();
  final TextEditingController _estimateController = TextEditingController();

  IncomeType? _selectedType;
  bool _isSaving = false;

  @override
  void dispose() {
    _estimateController.dispose();
    super.dispose();
  }

  /// Parse user input to double, handling commas and empty strings.
  double? _parseEstimate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _handleContinue() async {
    if (_selectedType == null) return;

    setState(() => _isSaving = true);

    try {
      final estimate = _parseEstimate(_estimateController.text);
      await _incomeRepository.updateIncomeProfile(
        type: _selectedType!,
        monthlyEstimate: estimate,
      );
      widget.onContinue();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save income profile. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                l10n.incomeSetupTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                l10n.incomeSetupSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: ListView(
                  children: [
                    _buildIncomeTypeCard(
                      type: IncomeType.fixed,
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.incomeTypeFixed,
                      description: l10n.incomeTypeFixedDesc,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    SizedBox(height: 1.5.h),
                    _buildIncomeTypeCard(
                      type: IncomeType.variable,
                      icon: Icons.trending_up,
                      title: l10n.incomeTypeVariable,
                      description: l10n.incomeTypeVariableDesc,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    SizedBox(height: 1.5.h),
                    _buildIncomeTypeCard(
                      type: IncomeType.mixed,
                      icon: Icons.compare_arrows,
                      title: l10n.incomeTypeMixed,
                      description: l10n.incomeTypeMixedDesc,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    SizedBox(height: 3.h),
                    _buildEstimateInput(
                      theme: theme,
                      colorScheme: colorScheme,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedType != null && !_isSaving ? _handleContinue : null,
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

  Widget _buildIncomeTypeCard({
    required IncomeType type,
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedType == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
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
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 6.w,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  size: 6.w,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateInput({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.monthlyEstimateLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _estimateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: l10n.monthlyEstimateHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 2.h,
            ),
          ),
        ),
      ],
    );
  }
}
