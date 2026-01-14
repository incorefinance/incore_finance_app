import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:incore_finance/widgets/custom_bottom_bar.dart';
import 'package:incore_finance/presentation/add_transaction/add_transaction.dart';
import '../../core/app_export.dart';
import '../../main.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../utils/snackbar_helper.dart';
import './widgets/currency_selector_dialog.dart';
import './widgets/export_options_dialog.dart';
import './widgets/language_selector_dialog.dart';
import './widgets/setting_section_header.dart';
import './widgets/setting_tile.dart';

/// Settings screen for app configuration and preferences
/// Provides comprehensive settings management with grouped sections
/// and persistent storage via SharedPreferences.
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Current settings state
  String _currentLanguage = 'en';
  bool _isDarkMode = false;
  String _currentCurrency = 'USD';
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _goalMilestonesEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _spendingAlertsEnabled = true;
  bool _googleSheetsSync = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'en';
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _currentCurrency = prefs.getString('currency') ?? 'USD';
      _biometricEnabled = prefs.getBool('biometric') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _goalMilestonesEnabled = prefs.getBool('goalMilestones') ?? true;
      _weeklySummaryEnabled = prefs.getBool('weeklySummary') ?? true;
      _spendingAlertsEnabled = prefs.getBool('spendingAlerts') ?? true;
      _googleSheetsSync = prefs.getBool('googleSheetsSync') ?? false;
    });
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('currency', _currentCurrency);
    await prefs.setBool('biometric', _biometricEnabled);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('goalMilestones', _goalMilestonesEnabled);
    await prefs.setBool('weeklySummary', _weeklySummaryEnabled);
    await prefs.setBool('spendingAlerts', _spendingAlertsEnabled);
    await prefs.setBool('googleSheetsSync', _googleSheetsSync);
  }

  /// Toggle dark mode and update app theme
  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveSettings();
    MyApp.setLocale(context, Locale(_currentLanguage));
  }

  /// Toggle biometric authentication
  void _toggleBiometric(bool value) {
    setState(() {
      _biometricEnabled = value;
    });
    _saveSettings();
  }

  /// Toggle notifications
  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    _saveSettings();
  }

  /// Toggle goal milestones
  void _toggleGoalMilestones(bool value) {
    setState(() {
      _goalMilestonesEnabled = value;
    });
    _saveSettings();
  }

  /// Toggle weekly summary emails
  void _toggleWeeklySummary(bool value) {
    setState(() {
      _weeklySummaryEnabled = value;
    });
    _saveSettings();
  }

  /// Toggle spending alerts
  void _toggleSpendingAlerts(bool value) {
    setState(() {
      _spendingAlertsEnabled = value;
    });
    _saveSettings();
  }

  /// Toggle Google Sheets sync
  void _toggleGoogleSheetsSync(bool value) {
    setState(() {
      _googleSheetsSync = value;
    });
    _saveSettings();
  }

  /// Show language selector dialog
  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => LanguageSelectorDialog(
        currentLanguage: _currentLanguage,
        onLanguageSelected: (language) {
          setState(() {
            _currentLanguage = language;
          });
          _saveSettings();
          MyApp.setLocale(context, Locale(language));

          final l10n = AppLocalizations.of(context)!;
          SnackbarHelper.showSuccess(context, l10n.languageUpdated);
        },
      ),
    );
  }

  /// Show currency selector dialog
  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder: (context) => CurrencySelectorDialog(
        currentCurrency: _currentCurrency,
        onCurrencySelected: (currency) {
          setState(() {
            _currentCurrency = currency;
          });
          _saveSettings();

          final l10n = AppLocalizations.of(context)!;
          SnackbarHelper.showSuccess(
            context,
            l10n.currencyUpdated(_currentCurrency),
          );
        },
      ),
    );
  }

  /// Show export options dialog
  Future<void> _showExportOptions() async {
    await showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        onExportSelected: (format) {
          final l10n = AppLocalizations.of(context)!;
          SnackbarHelper.showSuccess(
            context,
            l10n.exportStarted(format),
          );
        },
      ),
    );
  }

  /// Reset all data confirmation dialog
  void _confirmResetData() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetDataTitle),
        content: Text(l10n.resetDataDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetData();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// Reset all local data (demo implementation)
  Future<void> _resetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showSuccess(
        context,
        l10n.dataResetSuccess,
      );
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Failed to reset data: $e',
      );
    }
  }

  /// Show about dialog
  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;

    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: '1.0.0',
      applicationIcon: const CustomIconWidget(iconName: 'show_chart'),
      children: [
        Text(
          l10n.aboutDescription,
          style: TextStyle(
            fontSize: 11.sp,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: l10n.settings,
        ),
        bottomNavigationBar: CustomBottomBar(
          currentItem: BottomBarItem.settings,
          onItemSelected: (item) {}, // CustomBottomBar handles navigation internally
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingSectionHeader(title: l10n.generalSettings),
              SettingTile(
                iconName: 'language',
                title: l10n.language,
                subtitle: _currentLanguage == 'en'
                    ? l10n.languageEnglish
                    : l10n.languagePortuguese,
                onTap: _showLanguageSelector,
              ),
              SettingTile(
                iconName: 'dark_mode',
                title: l10n.darkMode,
                subtitle:
                    _isDarkMode ? l10n.darkModeEnabled : l10n.darkModeDisabled,
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                ),
              ),
              SettingTile(
                iconName: 'attach_money',
                title: l10n.currency,
                subtitle: _currentCurrency,
                onTap: _showCurrencySelector,
              ),
              SizedBox(height: 3.h),
              SettingSectionHeader(title: l10n.privacySecurity),
              SettingTile(
                iconName: 'fingerprint',
                title: l10n.biometricAuth,
                subtitle: _biometricEnabled
                    ? l10n.biometricEnabled
                    : l10n.biometricDisabled,
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ),
              SettingTile(
                iconName: 'notifications',
                title: l10n.notifications,
                subtitle: _notificationsEnabled
                    ? l10n.notificationsEnabled
                    : l10n.notificationsDisabled,
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              ),
              SizedBox(height: 3.h),
              SettingSectionHeader(title: l10n.goalsAndTracking),
              SettingTile(
                iconName: 'flag',
                title: l10n.goalMilestones,
                subtitle: _goalMilestonesEnabled
                    ? l10n.goalMilestonesEnabled
                    : l10n.goalMilestonesDisabled,
                trailing: Switch(
                  value: _goalMilestonesEnabled,
                  onChanged: _toggleGoalMilestones,
                ),
              ),
              SettingTile(
                iconName: 'email',
                title: l10n.weeklySummary,
                subtitle: _weeklySummaryEnabled
                    ? l10n.weeklySummaryEnabled
                    : l10n.weeklySummaryDisabled,
                trailing: Switch(
                  value: _weeklySummaryEnabled,
                  onChanged: _toggleWeeklySummary,
                ),
              ),
              SettingTile(
                iconName: 'warning',
                title: l10n.spendingAlerts,
                subtitle: _spendingAlertsEnabled
                    ? l10n.spendingAlertsEnabled
                    : l10n.spendingAlertsDisabled,
                trailing: Switch(
                  value: _spendingAlertsEnabled,
                  onChanged: _toggleSpendingAlerts,
                ),
              ),
              SizedBox(height: 3.h),
              SettingSectionHeader(title: l10n.dataAndExport),
              SettingTile(
                iconName: 'upload_file',
                title: l10n.exportData,
                subtitle: l10n.exportDataDescription,
                onTap: _showExportOptions,
              ),
              SettingTile(
                iconName: 'link',
                title: l10n.googleSheetsSync,
                subtitle: _googleSheetsSync
                    ? l10n.googleSheetsSyncEnabled
                    : l10n.googleSheetsSyncDisabled,
                trailing: Switch(
                  value: _googleSheetsSync,
                  onChanged: _toggleGoogleSheetsSync,
                ),
              ),
              SettingTile(
                iconName: 'restore',
                title: l10n.resetDataTitle,
                subtitle: l10n.resetDataDescriptionShort,
                onTap: _confirmResetData,
              ),
              SizedBox(height: 3.h),
              SettingSectionHeader(title: l10n.aboutSection),
              SettingTile(
                iconName: 'info_outline',
                title: l10n.aboutTitle,
                subtitle: l10n.aboutDescriptionShort,
                onTap: _showAboutDialog,
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
