import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog for selecting an import format or downloading the Excel template.
///
/// Mirrors [ExportOptionsDialog] in structure and styling.
/// Includes a collapsible format guide so users know the expected columns
/// before they pick a file.
class ImportDialog extends StatefulWidget {
  final void Function(String format) onFormatSelected;
  final VoidCallback onDownloadTemplate;

  const ImportDialog({
    super.key,
    required this.onFormatSelected,
    required this.onDownloadTemplate,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  bool _guideExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Choose a file to import or download the template first',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.slate500,
              ),
            ),
            SizedBox(height: 1.5.h),

            // ── Format guide ──────────────────────────────────────────────
            _buildGuide(context, theme),

            SizedBox(height: 1.5.h),

            // CSV option
            _buildOption(
              context: context,
              iconName: 'table_chart',
              title: 'CSV File',
              subtitle: 'Comma-separated values (.csv)',
              format: 'csv',
              theme: theme,
            ),

            SizedBox(height: 1.5.h),

            // Excel option
            _buildOption(
              context: context,
              iconName: 'grid_on',
              title: 'Excel File',
              subtitle: 'Microsoft Excel (.xlsx)',
              format: 'excel',
              theme: theme,
            ),

            SizedBox(height: 2.h),
            Divider(color: context.dividerGlass60, height: 1),
            SizedBox(height: 1.h),

            // Download template
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDownloadTemplate();
                },
                icon: CustomIconWidget(
                  iconName: 'download',
                  size: 4.5.w,
                  color: context.blue600,
                ),
                label: Text(
                  'Download Excel template',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.blue600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: context.blue600,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: context.slate500,
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuide(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: context.blue50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderGlass60),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          InkWell(
            onTap: () => setState(() => _guideExpanded = !_guideExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    size: 4.w,
                    color: context.blue600,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Format guide',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.blue600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _guideExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 4.5.w,
                    color: context.blue600,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_guideExpanded) ...[
            Divider(height: 1, color: context.borderGlass60),
            Padding(
              padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _guideRow(theme, 'date', required: true, hint: 'YYYY-MM-DD  (e.g. 2025-01-15)'),
                  _guideRow(theme, 'type', required: true, hint: 'income  or  expense'),
                  _guideRow(theme, 'amount', required: true, hint: 'Positive number  (e.g. 5000.00)'),
                  _guideRow(theme, 'description', required: false, hint: 'Optional free text'),
                  _guideRow(theme, 'category', required: true, hint: 'e.g. Consulting, Software, Rent'),
                  _guideRow(theme, 'payment_method', required: true, hint: 'Cash, Card, Bank Transfer…'),
                  _guideRow(theme, 'client', required: false, hint: 'Optional free text'),
                  SizedBox(height: 0.6.h),
                  Text(
                    'Download the template for sample data and full category list.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.slate500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guideRow(
    ThemeData theme,
    String column, {
    required bool required,
    required String hint,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24.w,
            child: Text(
              column,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: required ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            required ? '✓' : '–',
            style: theme.textTheme.bodySmall?.copyWith(
              color: required ? const Color(0xFF14B8A6) : Colors.black38,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String iconName,
    required String title,
    required String subtitle,
    required String format,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onFormatSelected(format);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderGlass60),
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
                    SizedBox(height: 0.3.h),
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
