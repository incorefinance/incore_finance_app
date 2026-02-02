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

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get down;

  /// No description provided for @authErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get authErrorTitle;

  /// No description provided for @authErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please log in again to continue.'**
  String get authErrorDescription;

  /// No description provided for @logInAgain.
  ///
  /// In en, this message translates to:
  /// **'Log in again'**
  String get logInAgain;

  /// No description provided for @upcomingBills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get upcomingBills;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get addBill;

  /// No description provided for @manageBills.
  ///
  /// In en, this message translates to:
  /// **'Manage bills'**
  String get manageBills;

  /// No description provided for @viewAllRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'View all {count} recurring expenses'**
  String viewAllRecurringExpenses(int count);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String dueInDays(int days);

  /// No description provided for @dueOnDay.
  ///
  /// In en, this message translates to:
  /// **'Due on {day}/{month}'**
  String dueOnDay(int day, int month);

  /// No description provided for @dueOnDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Due on day {day}'**
  String dueOnDayOfMonth(int day);

  /// No description provided for @noRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'No recurring expenses'**
  String get noRecurringExpenses;

  /// No description provided for @addRecurringExpensesHint.
  ///
  /// In en, this message translates to:
  /// **'Add recurring expenses to see upcoming bills and short term pressure.'**
  String get addRecurringExpensesHint;

  /// No description provided for @setUpRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Set up recurring expenses'**
  String get setUpRecurringExpenses;

  /// No description provided for @recurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expenses'**
  String get recurringExpenses;

  /// No description provided for @addRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Add recurring expense'**
  String get addRecurringExpense;

  /// No description provided for @editRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring expense'**
  String get editRecurringExpense;

  /// No description provided for @recurringExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense added successfully!'**
  String get recurringExpenseAdded;

  /// No description provided for @recurringExpenseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense updated successfully!'**
  String get recurringExpenseUpdated;

  /// No description provided for @failedToSaveRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Failed to save recurring expense. Please try again.'**
  String get failedToSaveRecurringExpense;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., Internet bill'**
  String get namePlaceholder;

  /// No description provided for @amountPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 50.00'**
  String get amountPlaceholder;

  /// No description provided for @dueDay.
  ///
  /// In en, this message translates to:
  /// **'Due day'**
  String get dueDay;

  /// No description provided for @dueDayHint.
  ///
  /// In en, this message translates to:
  /// **'1-31'**
  String get dueDayHint;

  /// No description provided for @dueDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Day of the month when bill is due (1-31)'**
  String get dueDayHelp;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{name}\"?'**
  String deleteConfirmMessage(String name);

  /// No description provided for @validAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than zero'**
  String get validAmountError;

  /// No description provided for @dueDayRangeError.
  ///
  /// In en, this message translates to:
  /// **'Due day must be between 1 and 31'**
  String get dueDayRangeError;

  /// No description provided for @failedToLoadTransactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions'**
  String get failedToLoadTransactions;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get tryAdjustingFilters;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @searchByDescriptionOrClient.
  ///
  /// In en, this message translates to:
  /// **'Search by description or client'**
  String get searchByDescriptionOrClient;

  /// No description provided for @filtersApplied.
  ///
  /// In en, this message translates to:
  /// **'Filters applied'**
  String get filtersApplied;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'This transaction will be removed from your list. You can undo this action.'**
  String get deleteTransactionConfirm;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @lastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastSevenDays;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @monthOverMonth.
  ///
  /// In en, this message translates to:
  /// **'Month over Month'**
  String get monthOverMonth;

  /// No description provided for @comparedWithLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Compared with last month'**
  String get comparedWithLastMonth;

  /// No description provided for @percentOfExpenses.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of expenses'**
  String percentOfExpenses(String percent);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @addTransactionsToSeeTrends.
  ///
  /// In en, this message translates to:
  /// **'Add a few transactions to see trends and breakdowns'**
  String get addTransactionsToSeeTrends;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @transactionAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully!'**
  String get transactionAddedSuccess;

  /// No description provided for @transactionUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated successfully!'**
  String get transactionUpdatedSuccess;

  /// No description provided for @failedToAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to add transaction. Please try again.'**
  String get failedToAddTransaction;

  /// No description provided for @enterClientHint.
  ///
  /// In en, this message translates to:
  /// **'Enter client name'**
  String get enterClientHint;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @catSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get catSales;

  /// No description provided for @catFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get catFreelance;

  /// No description provided for @catConsulting.
  ///
  /// In en, this message translates to:
  /// **'Consulting'**
  String get catConsulting;

  /// No description provided for @catRetainers.
  ///
  /// In en, this message translates to:
  /// **'Retainers'**
  String get catRetainers;

  /// No description provided for @catSubscriptionsIncome.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get catSubscriptionsIncome;

  /// No description provided for @catCommissions.
  ///
  /// In en, this message translates to:
  /// **'Commissions'**
  String get catCommissions;

  /// No description provided for @catInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get catInterest;

  /// No description provided for @catRefundsIncome.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get catRefundsIncome;

  /// No description provided for @catOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get catOtherIncome;

  /// No description provided for @catAdvertising.
  ///
  /// In en, this message translates to:
  /// **'Advertising'**
  String get catAdvertising;

  /// No description provided for @catSoftware.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get catSoftware;

  /// No description provided for @catSubscriptionsExpense.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get catSubscriptionsExpense;

  /// No description provided for @catEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catEquipment;

  /// No description provided for @catSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get catSupplies;

  /// No description provided for @catAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get catAccounting;

  /// No description provided for @catContractors.
  ///
  /// In en, this message translates to:
  /// **'Contractors'**
  String get catContractors;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get catMeals;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get catInsurance;

  /// No description provided for @catTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get catTaxes;

  /// No description provided for @catFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get catFees;

  /// No description provided for @catSalaries.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get catSalaries;

  /// No description provided for @catTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get catTraining;

  /// No description provided for @catOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other Expense'**
  String get catOtherExpense;

  /// No description provided for @payMbWay.
  ///
  /// In en, this message translates to:
  /// **'MB Way'**
  String get payMbWay;

  /// No description provided for @payPaypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get payPaypal;

  /// No description provided for @payDirectDebit.
  ///
  /// In en, this message translates to:
  /// **'Direct Debit'**
  String get payDirectDebit;

  /// No description provided for @networkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Problem'**
  String get networkErrorTitle;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get networkErrorMessage;

  /// No description provided for @unknownErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get unknownErrorTitle;

  /// No description provided for @unknownErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unknownErrorMessage;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumPlan;

  /// No description provided for @freeDescription.
  ///
  /// In en, this message translates to:
  /// **'Basic features with usage limits'**
  String get freeDescription;

  /// No description provided for @premiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Full access to all features'**
  String get premiumDescription;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @manageSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Open your device settings to manage your subscription'**
  String get manageSubscriptionHint;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored successfully'**
  String get purchasesRestored;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore purchases'**
  String get restoreFailed;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// No description provided for @featureAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics and insights'**
  String get featureAnalytics;

  /// No description provided for @featureHistoricalData.
  ///
  /// In en, this message translates to:
  /// **'Access to historical data'**
  String get featureHistoricalData;

  /// No description provided for @featureExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data to PDF and CSV'**
  String get featureExportData;

  /// No description provided for @featureUnlimitedEntries.
  ///
  /// In en, this message translates to:
  /// **'Unlimited transactions and entries'**
  String get featureUnlimitedEntries;

  /// No description provided for @limitReachedMonthly.
  ///
  /// In en, this message translates to:
  /// **'You have reached your free plan limit for this month'**
  String get limitReachedMonthly;

  /// No description provided for @limitReachedRecurring.
  ///
  /// In en, this message translates to:
  /// **'You have reached your free plan limit for active recurring expenses'**
  String get limitReachedRecurring;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get deleteAccountConfirm;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @availableOnMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Available on mobile only'**
  String get availableOnMobileOnly;

  /// No description provided for @restorePurchasesDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore previous purchases'**
  String get restorePurchasesDesc;

  /// No description provided for @firstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'First Day of Week'**
  String get firstDayOfWeek;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @resetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset Onboarding'**
  String get resetOnboarding;

  /// No description provided for @resetOnboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Go through setup again'**
  String get resetOnboardingDesc;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get clearCacheDesc;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @diagnosticsDesc.
  ///
  /// In en, this message translates to:
  /// **'View app information'**
  String get diagnosticsDesc;

  /// No description provided for @buildVersion.
  ///
  /// In en, this message translates to:
  /// **'Build Version'**
  String get buildVersion;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @lastError.
  ///
  /// In en, this message translates to:
  /// **'Last Error'**
  String get lastError;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @contactSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help with the app'**
  String get contactSupportDesc;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'View our privacy policy'**
  String get privacyPolicyDesc;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'View terms and conditions'**
  String get termsOfServiceDesc;

  /// No description provided for @upgradeForExport.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to export data'**
  String get upgradeForExport;

  /// No description provided for @incomeSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Income setup'**
  String get incomeSetupTitle;

  /// No description provided for @incomeSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what best matches your income'**
  String get incomeSetupSubtitle;

  /// No description provided for @incomeTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed income'**
  String get incomeTypeFixed;

  /// No description provided for @incomeTypeFixedDesc.
  ///
  /// In en, this message translates to:
  /// **'Consistent monthly amount like salary'**
  String get incomeTypeFixedDesc;

  /// No description provided for @incomeTypeVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable income'**
  String get incomeTypeVariable;

  /// No description provided for @incomeTypeVariableDesc.
  ///
  /// In en, this message translates to:
  /// **'Changes month to month like freelance'**
  String get incomeTypeVariableDesc;

  /// No description provided for @incomeTypeMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed income'**
  String get incomeTypeMixed;

  /// No description provided for @incomeTypeMixedDesc.
  ///
  /// In en, this message translates to:
  /// **'Combination of fixed and variable'**
  String get incomeTypeMixedDesc;

  /// No description provided for @monthlyEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly estimate (optional)'**
  String get monthlyEstimateLabel;

  /// No description provided for @monthlyEstimateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your typical monthly income'**
  String get monthlyEstimateHint;
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
