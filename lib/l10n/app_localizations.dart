import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'InCore Finance'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'MMMM dd, yyyy'**
  String get dateFormat;

  /// No description provided for @monthlyProfit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Profit'**
  String get monthlyProfit;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @topExpenses.
  ///
  /// In en, this message translates to:
  /// **'Top Expenses'**
  String get topExpenses;

  /// No description provided for @cashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance'**
  String get cashBalance;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @comparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'This Month vs Last Month'**
  String get comparisonTitle;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @categoryAdvertising.
  ///
  /// In en, this message translates to:
  /// **'Advertising and marketing'**
  String get categoryAdvertising;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent and utilities'**
  String get categoryRent;

  /// No description provided for @categorySoftware.
  ///
  /// In en, this message translates to:
  /// **'Website and software'**
  String get categorySoftware;

  /// No description provided for @categorySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get categorySubscriptions;

  /// No description provided for @categoryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment and hardware'**
  String get categoryEquipment;

  /// No description provided for @categorySupplies.
  ///
  /// In en, this message translates to:
  /// **'Office supplies'**
  String get categorySupplies;

  /// No description provided for @categoryAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting and legal'**
  String get categoryAccounting;

  /// No description provided for @categoryContractors.
  ///
  /// In en, this message translates to:
  /// **'Contractors and outsourcing'**
  String get categoryContractors;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals and entertainment business'**
  String get categoryMeals;

  /// No description provided for @categoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get categoryInsurance;

  /// No description provided for @categoryTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get categoryTaxes;

  /// No description provided for @categoryFees.
  ///
  /// In en, this message translates to:
  /// **'Bank and payment fees'**
  String get categoryFees;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary and payroll'**
  String get categorySalary;

  /// No description provided for @categoryTraining.
  ///
  /// In en, this message translates to:
  /// **'Benefits and training'**
  String get categoryTraining;

  /// No description provided for @categoryOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other expense'**
  String get categoryOtherExpense;

  /// No description provided for @categoryRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds and adjustments'**
  String get categoryRefunds;

  /// No description provided for @categorySales.
  ///
  /// In en, this message translates to:
  /// **'Sales and revenue'**
  String get categorySales;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your business finances by adding your first transaction'**
  String get noTransactionsDesc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @mobilePay.
  ///
  /// In en, this message translates to:
  /// **'Mobile Pay'**
  String get mobilePay;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @optionalClient.
  ///
  /// In en, this message translates to:
  /// **'Client (optional)'**
  String get optionalClient;

  /// No description provided for @quickTemplates.
  ///
  /// In en, this message translates to:
  /// **'Quick Templates'**
  String get quickTemplates;

  /// No description provided for @clientPayment.
  ///
  /// In en, this message translates to:
  /// **'Client Payment'**
  String get clientPayment;

  /// No description provided for @monthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Salary'**
  String get monthlySalary;

  /// No description provided for @coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffee;

  /// No description provided for @gas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get gas;

  /// No description provided for @software.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get software;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @financialAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Financial Analytics'**
  String get financialAnalytics;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @incomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expenses'**
  String get incomeVsExpenses;

  /// No description provided for @profitTrends.
  ///
  /// In en, this message translates to:
  /// **'Profit Trends'**
  String get profitTrends;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @financialRatios.
  ///
  /// In en, this message translates to:
  /// **'Financial Ratios'**
  String get financialRatios;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get profitMargin;

  /// No description provided for @savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get savingsRate;

  /// No description provided for @expenseRatio.
  ///
  /// In en, this message translates to:
  /// **'Expense Ratio'**
  String get expenseRatio;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE & REGION'**
  String get languageAndRegion;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @primaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Primary Currency'**
  String get primaryCurrency;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get security;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @faceIdTouchId.
  ///
  /// In en, this message translates to:
  /// **'Face ID / Touch ID enabled'**
  String get faceIdTouchId;

  /// No description provided for @changePIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePIN;

  /// No description provided for @updateSecurityPIN.
  ///
  /// In en, this message translates to:
  /// **'Update your security PIN'**
  String get updateSecurityPIN;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'DATA MANAGEMENT'**
  String get dataManagement;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @downloadFinancialData.
  ///
  /// In en, this message translates to:
  /// **'Download your financial data'**
  String get downloadFinancialData;

  /// No description provided for @googleSheetsSync.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets Sync'**
  String get googleSheetsSync;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @manageBackups.
  ///
  /// In en, this message translates to:
  /// **'Manage your data backups'**
  String get manageBackups;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// No description provided for @goalMilestones.
  ///
  /// In en, this message translates to:
  /// **'Goal Milestones'**
  String get goalMilestones;

  /// No description provided for @goalMilestonesDesc.
  ///
  /// In en, this message translates to:
  /// **'Alerts when you reach savings goals'**
  String get goalMilestonesDesc;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @weeklySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Financial overview every Monday'**
  String get weeklySummaryDesc;

  /// No description provided for @spendingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Spending Alerts'**
  String get spendingAlerts;

  /// No description provided for @spendingAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Warnings when approaching limits'**
  String get spendingAlertsDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact us'**
  String get supportDesc;

  /// No description provided for @resetAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset All Settings'**
  String get resetAllSettings;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset All Settings?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset all settings to their default values. This action cannot be undone.'**
  String get resetConfirmMessage;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdated;

  /// No description provided for @currencyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Currency updated to {currency}'**
  String currencyUpdated(String currency);

  /// No description provided for @themeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme updated'**
  String get themeUpdated;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication disabled'**
  String get biometricDisabled;

  /// No description provided for @googleSheetsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets sync enabled'**
  String get googleSheetsEnabled;

  /// No description provided for @googleSheetsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets sync disabled'**
  String get googleSheetsDisabled;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsReset;

  /// No description provided for @pinChangeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'PIN change feature coming soon'**
  String get pinChangeComingSoon;

  /// No description provided for @backupComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Backup feature coming soon'**
  String get backupComingSoon;

  /// No description provided for @openingPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Opening privacy policy...'**
  String get openingPrivacyPolicy;

  /// No description provided for @openingSupport.
  ///
  /// In en, this message translates to:
  /// **'Opening support...'**
  String get openingSupport;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'Exporting data as {format}...'**
  String exportingData(String format);

  /// No description provided for @switchToPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Switch to Portuguese'**
  String get switchToPortuguese;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get switchToEnglish;

  /// No description provided for @transactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved successfully'**
  String get transactionSaved;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @transactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get transactionUpdated;

  /// No description provided for @errorSavingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Error saving transaction'**
  String get errorSavingTransaction;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fillRequiredFields;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard data'**
  String get failedToLoadDashboard;

  /// No description provided for @someDashboardDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Some dashboard data could not be loaded. Pull to refresh to try again.'**
  String get someDashboardDataFailed;

  /// No description provided for @noExpensesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded this month yet'**
  String get noExpensesRecorded;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @netLoss.
  ///
  /// In en, this message translates to:
  /// **'Net Loss'**
  String get netLoss;

  /// No description provided for @cashBalanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance Trend'**
  String get cashBalanceTrend;

  /// No description provided for @thirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get thirtyDays;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @threeMonths.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get threeMonths;

  /// No description provided for @sixMonths.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get sixMonths;

  /// No description provided for @twelveMonths.
  ///
  /// In en, this message translates to:
  /// **'12M'**
  String get twelveMonths;

  /// No description provided for @performanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Performance overview'**
  String get performanceOverview;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet.'**
  String get notEnoughData;

  /// No description provided for @incomeVsExpensesChart.
  ///
  /// In en, this message translates to:
  /// **'Income vs expenses'**
  String get incomeVsExpensesChart;

  /// No description provided for @incomeSources.
  ///
  /// In en, this message translates to:
  /// **'Income sources'**
  String get incomeSources;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense breakdown'**
  String get expenseBreakdown;

  /// No description provided for @exportAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Export Analytics'**
  String get exportAnalytics;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @generatePdfReport.
  ///
  /// In en, this message translates to:
  /// **'Generate comprehensive PDF report'**
  String get generatePdfReport;

  /// No description provided for @exportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCsv;

  /// No description provided for @downloadCsvData.
  ///
  /// In en, this message translates to:
  /// **'Download data in spreadsheet format'**
  String get downloadCsvData;

  /// No description provided for @reportExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{format} report exported successfully'**
  String reportExportedSuccessfully(String format);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @notEnoughDataForTrends.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet to show trends.'**
  String get notEnoughDataForTrends;

  /// No description provided for @profitImproved.
  ///
  /// In en, this message translates to:
  /// **'Profit improved compared to last month.'**
  String get profitImproved;

  /// No description provided for @profitDecreased.
  ///
  /// In en, this message translates to:
  /// **'Profit decreased compared to last month.'**
  String get profitDecreased;

  /// No description provided for @profitStable.
  ///
  /// In en, this message translates to:
  /// **'Profit was stable compared to last month.'**
  String get profitStable;

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'{format} export started'**
  String exportStarted(String format);

  /// No description provided for @resetDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Data'**
  String get resetDataTitle;

  /// No description provided for @resetDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your financial data. This action cannot be undone.'**
  String get resetDataDescription;

  /// No description provided for @resetDataDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all data'**
  String get resetDataDescriptionShort;

  /// No description provided for @dataResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data has been reset successfully'**
  String get dataResetSuccess;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @goalsAndTracking.
  ///
  /// In en, this message translates to:
  /// **'Goals & Tracking'**
  String get goalsAndTracking;

  /// No description provided for @dataAndExport.
  ///
  /// In en, this message translates to:
  /// **'Data & Export'**
  String get dataAndExport;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About InCore Finance'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'InCore Finance helps you manage your business finances with ease. Track income, expenses, and gain insights into your financial health.'**
  String get aboutDescription;

  /// No description provided for @aboutDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Version and app information'**
  String get aboutDescriptionShort;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get darkModeEnabled;

  /// No description provided for @darkModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode disabled'**
  String get darkModeDisabled;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @goalMilestonesEnabled.
  ///
  /// In en, this message translates to:
  /// **'Goal milestones enabled'**
  String get goalMilestonesEnabled;

  /// No description provided for @goalMilestonesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Goal milestones disabled'**
  String get goalMilestonesDisabled;

  /// No description provided for @weeklySummaryEnabled.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary enabled'**
  String get weeklySummaryEnabled;

  /// No description provided for @weeklySummaryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary disabled'**
  String get weeklySummaryDisabled;

  /// No description provided for @spendingAlertsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Spending alerts enabled'**
  String get spendingAlertsEnabled;

  /// No description provided for @spendingAlertsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Spending alerts disabled'**
  String get spendingAlertsDisabled;

  /// No description provided for @googleSheetsSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets sync enabled'**
  String get googleSheetsSyncEnabled;

  /// No description provided for @googleSheetsSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets sync disabled'**
  String get googleSheetsSyncDisabled;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @exportDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Download your financial data'**
  String get exportDataDescription;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
