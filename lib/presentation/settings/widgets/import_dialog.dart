import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 85.h),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              l10n.importTransactionsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              l10n.importTransactionsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.slate500,
              ),
            ),
            SizedBox(height: 1.5.h),

            // ── Format guide ──────────────────────────────────────────────
            _buildGuide(context, theme, l10n: l10n),

            SizedBox(height: 1.5.h),

            // CSV option
            _buildOption(
              context: context,
              iconName: 'table_chart',
              title: l10n.csvFile,
              subtitle: l10n.csvFileSubtitle,
              format: 'csv',
              theme: theme,
            ),

            SizedBox(height: 1.5.h),

            // Excel option
            _buildOption(
              context: context,
              iconName: 'grid_on',
              title: l10n.excelFile,
              subtitle: l10n.excelFileDescription,
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
                  l10n.downloadExcelTemplate,
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
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
        ),
        ),
    );
  }

  Widget _buildGuide(BuildContext context, ThemeData theme, {required AppLocalizations l10n}) {
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
                      l10n.formatGuide,
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
                  _guideRow(theme, l10n.columnDate, required: true, hint: l10n.formatGuideDate),
                  _guideRow(theme, l10n.columnType, required: true, hint: l10n.formatGuideType),
                  _guideRow(theme, l10n.columnAmount, required: true, hint: l10n.formatGuideAmount),
                  _guideRow(theme, l10n.columnDescription, required: false, hint: l10n.formatGuideOptional),
                  _guideRow(theme, l10n.columnCategory, required: true, hint: l10n.formatGuideCategory),
                  _guideRow(theme, l10n.columnPaymentMethod, required: true, hint: l10n.formatGuidePayment),
                  _guideRow(theme, l10n.columnClient, required: false, hint: l10n.formatGuideOptional),
                  SizedBox(height: 0.6.h),
                  Text(
                    l10n.formatGuideDownloadHint,
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
            width: 28.w,
            child: Text(
              column,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: required ? context.slate900 : context.slate500,
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            required ? '✓' : '–',
            style: theme.textTheme.bodySmall?.copyWith(
              color: required ? context.teal600 : context.slate400,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.slate500,
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
