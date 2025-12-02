import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

abstract class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // App general
  String get appTitle;
  String get dashboard;
  String get analytics;
  String get settings;
  String get transactions;
  String get addTransaction;

  // General Settings
  String get generalSettings;
  String get language;
  String get languageEnglish;
  String get languagePortuguese;

  // Display Settings
  String get darkMode;
  String get darkModeEnabled;
  String get darkModeDisabled;

  // Privacy and Security
  String get privacySecurity;
  String get biometricAuth;
  String get biometricEnabled;
  String get biometricDisabled;

  // Notifications
  String get notifications;
  String get notificationsEnabled;
  String get notificationsDisabled;

  // Goals and Tracking
  String get goalsAndTracking;
  String get goalMilestones;
  String get goalMilestonesEnabled;
  String get goalMilestonesDisabled;

  // Data and Export
  String get dataAndExport;
  String get exportData;
  String get exportDataDescription;
  String get resetDataTitle;
  String get resetDataDescription;
  String get resetDataDescriptionShort;
  String get dataResetSuccess;

  // About Section
  String get aboutSection;
  String get aboutTitle;
  String get aboutDescription;
  String get aboutDescriptionShort;

  // Email notifications
  String get weeklySummary;
  String get weeklySummaryEnabled;
  String get weeklySummaryDisabled;
  String get spendingAlerts;
  String get spendingAlertsEnabled;
  String get spendingAlertsDisabled;

  // Google Sheets
  String get googleSheetsSync;
  String get googleSheetsSyncEnabled;
  String get googleSheetsSyncDisabled;

  // UI Actions
  String get cancel;
  String get confirm;
  String get currency;
  String get languageUpdated;

  // Methods with parameters
  String currencyUpdated(String currency);
  String exportStarted(String format);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pt'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'pt') {
      return AppLocalizationsPt();
    }
    return AppLocalizationsEn();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
