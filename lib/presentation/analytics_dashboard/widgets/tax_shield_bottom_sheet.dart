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

  static const _presets = [0.0, 0.15, 0.25, 0.30];

  @override
  void initState() {
    super.initState();
    _selectedPercent = widget.currentPercent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.canvasFrostedLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row with label and current value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.taxReserveTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate600,
                  ),
                ),
                Text(
                  '${(_selectedPercent * 100).round()}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.blue600,
                inactiveTrackColor: AppColors.slate400.withValues(alpha: 0.25),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                  elevation: 2,
                  pressedElevation: 4,
                ),
                overlayColor: AppColors.blue600.withValues(alpha: 0.12),
                trackHeight: 4,
              ),
              child: Slider(
                value: _selectedPercent,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                onChanged: (value) {
                  setState(() {
                    _selectedPercent = value;
                  });
                },
              ),
            ),

            SizedBox(height: 1.h),

            // Helper text
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.taxReserveBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.slate500,
                ),
              ),
            ),

            SizedBox(height: 2.5.h),

            // Preset chips
            Row(
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
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 3.h),

            // Action buttons
            Row(
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
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue600
              : AppColors.surfaceGlass80Light,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.borderGlass60Light,
                  width: 1,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : AppColors.slate500,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
