import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog for selecting export format
class ExportOptionsDialog extends StatelessWidget {
  final Function(String) onExportSelected;

  const ExportOptionsDialog({
    super.key,
    required this.onExportSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportData,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.chooseExportFormat,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.slate500,
              ),
            ),
            SizedBox(height: 3.h),

            // CSV option
            _buildExportOption(
              context: context,
              iconName: 'table_chart',
              title: l10n.csvFile,
              subtitle: l10n.csvFileDescription,
              format: 'csv',
              theme: theme,
              colorScheme: colorScheme,
            ),

            SizedBox(height: 1.5.h),

            // Excel option
            _buildExportOption(
              context: context,
              iconName: 'grid_on',
              title: l10n.excelFile,
              subtitle: l10n.excelFileDescription,
              format: 'excel',
              theme: theme,
              colorScheme: colorScheme,
            ),

            SizedBox(height: 3.h),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required BuildContext context,
    required String iconName,
    required String title,
    required String subtitle,
    required String format,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onExportSelected(format);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.borderGlass60,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: context.blue50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: iconName,
                    size: 6.w,
                    color: context.blue600,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'arrow_forward_ios',
                size: 4.w,
                color: context.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
