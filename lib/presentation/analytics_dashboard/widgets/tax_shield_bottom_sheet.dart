import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:incore_finance/l10n/app_localizations.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';

/// Bottom sheet for adjusting the tax shield percentage.
///
/// Displays preset chips (15%, 20%, 25%, 30%) and Save/Cancel actions.
class TaxShieldBottomSheet extends StatefulWidget {
  final double currentPercent;
  final ValueChanged<double> onSave;

  const TaxShieldBottomSheet({
    super.key,
    required this.currentPercent,
    required this.onSave,
  });

  @override
  State<TaxShieldBottomSheet> createState() => _TaxShieldBottomSheetState();
}

class _TaxShieldBottomSheetState extends State<TaxShieldBottomSheet> {
  late double _selectedPercent;

  static const _presets = [0.15, 0.20, 0.25, 0.30];

  @override
  void initState() {
    super.initState();
    _selectedPercent = widget.currentPercent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    l10n.taxReserveTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),

              SizedBox(height: 1.h),

              // Body text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.taxReserveBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 2.5.h),

              // Preset chips
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: _presets.map((preset) {
                    final isSelected = _selectedPercent == preset;
                    final label = '${(preset * 100).round()}%';
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: preset != _presets.last ? 8 : 0,
                        ),
                        child: _buildChip(
                          label: label,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedPercent = preset;
                            });
                          },
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 3.h),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 5.h),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSave(_selectedPercent);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(0, 5.h),
                        ),
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySoft.withValues(alpha: 0.12)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppColors.primarySoft
                : colorScheme.outline.withValues(alpha: 0.18),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? AppColors.primarySoft
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
