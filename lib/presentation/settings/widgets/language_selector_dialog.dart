import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog for selecting app language
class LanguageSelectorDialog extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectorDialog({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // English option
            _buildLanguageOption(
              context: context,
              language: 'English',
              code: 'en',
              flag: '🇺🇸',
              theme: theme,
              colorScheme: colorScheme,
            ),

            SizedBox(height: 1.h),

            // Portuguese option
            _buildLanguageOption(
              context: context,
              language: 'Português',
              code: 'pt',
              flag: '🇵🇹',
              theme: theme,
              colorScheme: colorScheme,
            ),

            SizedBox(height: 3.h),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () {
                    widget.onLanguageSelected(_selectedLanguage);
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String language,
    required String code,
    required String flag,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedLanguage == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLanguage = code;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.blue600
                      : AppColors.borderGlass60Light,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(flag, style: TextStyle(fontSize: 24)),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  language,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  size: 5.w,
                  color: AppColors.blue600,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
