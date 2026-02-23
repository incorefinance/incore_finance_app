import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/models/recurring_expense.dart';
import 'package:incore_finance/services/transactions_repository.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:incore_finance/services/recurring_expenses_repository.dart';
import 'package:incore_finance/services/user_financial_baseline_repository.dart';
import 'package:incore_finance/services/auth_guard.dart';
import 'package:incore_finance/services/recurring_expenses_auto_poster.dart';
import 'package:incore_finance/services/recurring_auto_poster_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/state/transactions_change_notifier.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/app_error_classifier.dart';
import '../../core/logging/app_logger.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors_ext.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/app_error_widget.dart';
import './widgets/monthly_profit_card.dart';
import './widgets/upcoming_bills_placeholder.dart';
import './widgets/upcoming_bills_card.dart';
import '../recurring_expenses/widgets/add_edit_recurring_expense_dialog.dart';
import '../../domain/safety_buffer/safety_buffer_calculator.dart';
import '../../domain/safety_buffer/safety_buffer_snapshot.dart';
import '../../domain/tax_shield/tax_shield_calculator.dart';
import '../../domain/tax_shield/tax_shield_snapshot.dart';
import '../../domain/budgeting/smoothed_budget_calculator.dart';
import '../../domain/budgeting/smoothed_budget_snapshot.dart';
import '../../domain/onboarding/income_type.dart';
import '../../data/settings/tax_shield_settings_store.dart';
import '../../data/settings/safety_buffer_settings_store.dart';
import '../../data/profile/user_income_repository.dart';
import '../../services/protection_ledger_repository.dart';
import '../../models/protection_snapshot.dart';
import './widgets/safety_buffer_card.dart';
import './widgets/safety_coverage_card.dart';
import './widgets/dashboard_hero_carousel_card.dart';

/// Dashboard Home Screen
/// Dashboard Home responsibility:
/// Show current financial position and short-term pressure.
/// No historical analysis or detailed breakdowns belong here.
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final TransactionsRepository _transactionsRepository =
      TransactionsRepository();
  final UserSettingsService _userSettingsService = UserSettingsService();
  final RecurringExpensesRepository _recurringExpensesRepository =
      RecurringExpensesRepository();
  final UserFinancialBaselineRepository _baselineRepository =
      UserFinancialBaselineRepository();
  final ProtectionLedgerRepository _protectionLedgerRepository =
      ProtectionLedgerRepository();
  final SafetyBufferSettingsStore _safetyBufferSettingsStore =
      SafetyBufferSettingsStore();
  final UserIncomeRepository _userIncomeRepository = UserIncomeRepository();

  double _cashBalance = 0.0;
  double _monthlyProfit = 0.0;
  double _prevMonthProfit = 0.0;
  bool _prevMonthHasData = false;
  bool _isProfit = true;
  double _profitPercentageChange = 0.0;

  bool _isLoadingDashboard = true;
  AppError? _loadError;
  List<RecurringExpense> _recurringBills = [];

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _currentMonthIncome = 0.0;
  double _currentMonthExpense = 0.0;

  SafetyBufferSnapshot? _safetyBufferSnapshot;
  ProtectionSnapshot? _protectionSnapshot;
  TaxShieldSnapshot? _taxShieldSnapshot;
  SmoothedBudgetSnapshot? _budgetSnapshot;
  double _taxShieldPercent = TaxShieldSettingsStore.defaultPercent;
  final TaxShieldSettingsStore _taxShieldSettingsStore =
      TaxShieldSettingsStore();

  UserCurrencySettings _currencySettings = const UserCurrencySettings(
    currencyCode: 'EUR',
    symbol: '€',
    locale: 'pt_PT',
  );

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings().then((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final settings = await _userSettingsService.getCurrencySettings();
      setState(() {
        _currencySettings = settings;
      });
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
      _loadError = null;
    });

    try {
      final now = DateTime.now();

      // Load all transactions to calculate cash balance
      final List<TransactionRecord> allTxs =
          await _transactionsRepository.getTransactionsForCurrentUserTyped();

      double totalIncome = 0;
      double totalExpense = 0;

      for (final tx in allTxs) {
        if (tx.type == 'income') {
          totalIncome += tx.amount;
        } else if (tx.type == 'expense') {
          totalExpense += tx.amount;
        }
      }

      // Load starting balance from baseline
      double startingBalance = 0.0;
      try {
        final baseline = await _baselineRepository.getBaselineForCurrentUser();
        if (baseline != null) {
          startingBalance = baseline.startingBalance;
        }
      } catch (_) {
        // Keep default if loading fails
      }

      final cashBalance = startingBalance + totalIncome - totalExpense;

      // Calculate current month profit
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);

      final currentMonthEnd =
          nextMonthStart.subtract(const Duration(milliseconds: 1));

      final List<TransactionRecord> currentTxs =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        currentMonthStart,
        currentMonthEnd,
      );

      double currentIncome = 0;
      double currentExpense = 0;

      for (final tx in currentTxs) {
        if (tx.type == 'income') {
          currentIncome += tx.amount;
        } else if (tx.type == 'expense') {
          currentExpense += tx.amount;
        }
      }

      final currentProfit = currentIncome - currentExpense;

      // Calculate previous month for comparison
      final prevMonthEnd = currentMonthStart.subtract(const Duration(days: 1));
      final prevMonthStart = DateTime(prevMonthEnd.year, prevMonthEnd.month, 1);

      final List<TransactionRecord> prevTxs =
          await _transactionsRepository.getTransactionsByDateRangeTyped(
        prevMonthStart,
        prevMonthEnd,
      );

      double prevIncome = 0;
      double prevExpense = 0;

      for (final tx in prevTxs) {
        if (tx.type == 'income') {
          prevIncome += tx.amount;
        } else if (tx.type == 'expense') {
          prevExpense += tx.amount;
        }
      }

      final prevProfit = prevIncome - prevExpense;
      final prevHasData = prevTxs.isNotEmpty;

      double profitPercentageChange = 0.0;
      if (prevProfit != 0) {
        profitPercentageChange =
            ((currentProfit - prevProfit) / prevProfit) * 100;
      }

      // Load recurring bills
      List<RecurringExpense> bills = [];
      try {
        bills = await _recurringExpensesRepository.getActiveRecurringExpenses();
      } catch (_) {
        // Keep empty list if loading fails
      }

      // Auto-post due recurring expenses (non-blocking, once per session)
      _autoPostRecurringExpenses();

      // ─── Safety Buffer Calculation (reuses already-loaded data) ───────────
      final taxPercent = await _taxShieldSettingsStore.getTaxShieldPercent();

      // Filter transactions to 180-day insight window (same as InsightDataPreparer)
      final insightCutoff = now.subtract(const Duration(days: 180));
      final insightTransactions = allTxs
          .where((tx) => tx.date.isAfter(insightCutoff))
          .toList();

      // Monthly fixed outflow from already-loaded recurring bills
      double monthlyFixedOutflow = 0.0;
      for (final bill in bills) {
        monthlyFixedOutflow += bill.amount.abs();
      }

      // Compute TaxShield (same calculator as Analytics)
      const taxCalc = TaxShieldCalculator();
      final taxShield = taxCalc.compute(
        now: now,
        latestBalance: cashBalance,
        insightTransactions: insightTransactions,
        taxShieldPercent: taxPercent,
      );

      // Compute SafetyBuffer (same calculator as Analytics)
      const bufferCalc = SafetyBufferCalculator();
      final safetyBuffer = bufferCalc.compute(
        taxShield: taxShield,
        monthlyFixedOutflow: monthlyFixedOutflow,
      );

      // ─── Protection Snapshot (from ledger) ─────────────────────────────────
      ProtectionSnapshot? protectionSnapshot;
      try {
        protectionSnapshot =
            await _protectionLedgerRepository.getProtectionSnapshot();
      } catch (e) {
        AppLogger.w('Failed to load protection snapshot', error: e);
        // Continue without snapshot - will fallback to legacy display
      }

      // ─── Smoothed Budget Calculation ───────────────────────────────────────
      SmoothedBudgetSnapshot? budgetSnapshot;
      try {
        final safetyPercent =
            await _safetyBufferSettingsStore.getSafetyBufferPercent();
        final (incomeType, _) = await _userIncomeRepository.getIncomeProfile();

        const budgetCalc = SmoothedBudgetCalculator();
        budgetSnapshot = budgetCalc.compute(
          now: now,
          transactions: allTxs,
          recurringExpenses: bills,
          incomeType: incomeType ?? IncomeType.variable,
          taxReservePercent: taxPercent,
          safetyReservePercent: safetyPercent,
        );
      } catch (e) {
        AppLogger.w('Failed to compute budget snapshot', error: e);
        // Continue without budget - carousel will show "keep tracking" message
      }

      // Guard against widget being disposed during async operations
      if (!mounted) return;

      setState(() {
        _cashBalance = cashBalance;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _currentMonthIncome = currentIncome;
        _currentMonthExpense = currentExpense;
        _monthlyProfit = currentProfit;
        _prevMonthProfit = prevProfit;
        _prevMonthHasData = prevHasData;
        _profitPercentageChange = profitPercentageChange;
        _isProfit = currentProfit >= 0;
        _recurringBills = bills;
        _safetyBufferSnapshot = safetyBuffer;
        _taxShieldSnapshot = taxShield;
        _taxShieldPercent = taxPercent;
        _protectionSnapshot = protectionSnapshot;
        _budgetSnapshot = budgetSnapshot;
        _isLoadingDashboard = false;
      });
    } catch (e, st) {
      AppLogger.e('Dashboard load error', error: e, stackTrace: st);
      final appError = AppErrorClassifier.classify(e, stackTrace: st);

      if (!mounted) return;

      // Route to auth error screen for auth failures
      if (appError.category == AppErrorCategory.auth) {
        AuthGuard.routeToErrorIfInvalid(context, reason: appError.debugReason);
        return;
      }

      setState(() {
        _isLoadingDashboard = false;
        _loadError = appError;
      });
    }
  }

  Future<void> _autoPostRecurringExpenses() async {
    if (!RecurringAutoPosterGuard.instance.shouldRun()) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        RecurringAutoPosterGuard.instance.markFailed();
        return;
      }

      final poster = RecurringExpensesAutoPoster();
      final count = await poster.postDueRecurringExpenses(
        userId: userId,
        now: DateTime.now(),
      );

      RecurringAutoPosterGuard.instance.markComplete();

      if (count > 0) {
        AppLogger.i('Auto-posted $count recurring expense transactions');
        TransactionsChangeNotifier.instance.markChanged();
        // Reload dashboard data to reflect new transactions
        if (mounted) _loadDashboardData();
      }
    } catch (e, st) {
      AppLogger.e('Auto-posting recurring expenses failed', error: e, stackTrace: st);
      RecurringAutoPosterGuard.instance.markFailed();
    }
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  String _getGreeting() {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  String _getFormattedDate() {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(locale.toString()).format(DateTime.now());
  }

  Future<void> _handleAddTransaction() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addTransaction);
    if (result == true) {
      await _handleRefresh();
    }
  }

  Future<void> _handleAddBill() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => const AddEditRecurringExpenseDialog(),
    );
    if (result == true) {
      await _handleRefresh();
    }
  }

  Future<void> _handleManageBills() async {
    final result = await Navigator.pushNamed(context, AppRoutes.recurringExpenses);
    if (result == true) {
      await _handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: context.canvasFrosted,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: context.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header: Greeting and Date
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(4.w, AppTheme.screenTopPadding, 4.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _getFormattedDate(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content: Loading, Error, or Dashboard blocks
              SliverToBoxAdapter(
                child: _isLoadingDashboard
                    ? Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                        child: SizedBox(
                          height: 20.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.primary,
                            ),
                          ),
                        ),
                      )
                    : _loadError != null
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 4.h),
                            child: AppErrorWidget(
                              error: _loadError!,
                              displayMode: AppErrorDisplayMode.inline,
                              onRetry: _loadDashboardData,
                            ),
                          )
                        : Column(
                        children: [
                          // Block 1: Hero Carousel (Safe to Spend / Total Balance / Monthly Budget)
                          DashboardHeroCarouselCard(
                            safeToSpend: _protectionSnapshot?.safeToSpend ?? _cashBalance,
                            balance: _protectionSnapshot?.balance ?? _cashBalance,
                            totalIncome: _totalIncome,
                            totalExpense: _totalExpense,
                            taxReserve: _protectionSnapshot?.taxProtected ?? 0,
                            safetyBuffer: _protectionSnapshot?.safetyProtected ?? 0,
                            locale: _currencySettings.locale,
                            symbol: _currencySettings.symbol,
                            currencyCode: _currencySettings.currencyCode,
                            onWalletPressed: null,
                            hasLifetimeIncome: _totalIncome > 0,
                            budgetSnapshot: _budgetSnapshot,
                            currentMonthIncome: _currentMonthIncome,
                            currentMonthExpense: _currentMonthExpense,
                          ),

                          // Block 2: Safety Coverage
                          if (_protectionSnapshot != null)
                            SafetyCoverageCard(
                              safetyProtected: _protectionSnapshot!.safetyProtected,
                              avgMonthlyExpenses: _protectionSnapshot!.avgMonthlyExpenses,
                              confidence: _protectionSnapshot!.confidence,
                              locale: _currencySettings.locale,
                              symbol: _currencySettings.symbol,
                              currencyCode: _currencySettings.currencyCode,
                            )
                          else if (_safetyBufferSnapshot != null &&
                              _taxShieldSnapshot != null)
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context)!;
                                return SafetyBufferCard(
                                  bufferDays: _safetyBufferSnapshot!.bufferDays,
                                  bufferWeeks: _safetyBufferSnapshot!.bufferWeeks,
                                  taxPercent: (_taxShieldPercent * 100).round(),
                                  taxAmount:
                                      _taxShieldSnapshot!.taxShieldReserved,
                                  qualifier: _safetyBufferSnapshot!.usedTwoMonths
                                      ? l10n.safetyBufferQualBasedOnLastTwoMonths
                                      : l10n.safetyBufferQualBasedOnLastMonth,
                                  currencyLocale: _currencySettings.locale,
                                  currencySymbol: _currencySettings.symbol,
                                );
                              },
                            ),

                          // Block 3: This Month Performance
                          MonthlyProfitCard(
                            profit: _monthlyProfit,
                            currentMonthIncome: _currentMonthIncome,
                            percentageChange: _profitPercentageChange,
                            prevMonthProfit: _prevMonthProfit,
                            prevMonthHasData: _prevMonthHasData,
                            isProfit: _isProfit,
                            locale: _currencySettings.locale,
                            symbol: _currencySettings.symbol,
                            currencyCode: _currencySettings.currencyCode,
                          ),

                          // Block 4: Upcoming Bills
                          _recurringBills.isEmpty
                              ? const UpcomingBillsPlaceholder()
                              : UpcomingBillsCard(
                                  bills: _recurringBills,
                                  locale: _currencySettings.locale,
                                  symbol: _currencySettings.symbol,
                                  currencyCode: _currencySettings.currencyCode,
                                  onAddBill: _handleAddBill,
                                  onManageBills: _handleManageBills,
                                ),
                        ],
                      ),
              ),

              // Bottom spacing - accounts for floating nav bar
              SliverToBoxAdapter(child: SizedBox(height: kBottomNavClearance)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.dashboard,
        onItemSelected: (_) {},
        onAddTransaction: _handleAddTransaction,
      ),
    );
  }
}
