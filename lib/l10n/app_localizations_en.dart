import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appTitle => 'Incore Finance';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get analytics => 'Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get transactions => 'Transactions';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeEnabled => 'Dark mode enabled';

  @override
  String get darkModeDisabled => 'Dark mode disabled';

  @override
  String get privacySecurity => 'Privacy and Security';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get biometricEnabled => 'Biometric login enabled';

  @override
  String get biometricDisabled => 'Biometric login disabled';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get goalsAndTracking => 'Goals and Tracking';

  @override
  String get goalMilestones => 'Goal Milestones';

  @override
  String get goalMilestonesEnabled => 'Milestones enabled';

  @override
  String get goalMilestonesDisabled => 'Milestones disabled';

  @override
  String get dataAndExport => 'Data and Export';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataDescription => 'Download your transaction history';

  @override
  String get resetDataTitle => 'Reset Data';

  @override
  String get resetDataDescription =>
      'This will delete all locally saved settings and preferences.';

  @override
  String get resetDataDescriptionShort => 'Erase all saved preferences';

  @override
  String get dataResetSuccess => 'Data reset successfully!';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutTitle => 'About Incore Finance';

  @override
  String get aboutDescription =>
      'Incore Finance helps you manage your finances with clarity and control.';

  @override
  String get aboutDescriptionShort =>
      'Learn more about Incore Finance';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get weeklySummaryEnabled => 'Weekly emails enabled';

  @override
  String get weeklySummaryDisabled => 'Weekly emails disabled';

  @override
  String get spendingAlerts => 'Spending Alerts';

  @override
  String get spendingAlertsEnabled => 'Alerts enabled';

  @override
  String get spendingAlertsDisabled => 'Alerts disabled';

  @override
  String get googleSheetsSync => 'Google Sheets Sync';

  @override
  String get googleSheetsSyncEnabled => 'Sync enabled';

  @override
  String get googleSheetsSyncDisabled => 'Sync disabled';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get currency => 'Currency';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String currencyUpdated(String currency) =>
      'Currency updated to $currency';

  @override
  String exportStarted(String format) =>
      'Export started in $format format';
}
