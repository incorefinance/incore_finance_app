import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../domain/budgeting/smoothed_budget_snapshot.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Dashboard Hero Carousel Card - Revolut-style swipeable hero with three pages.
/// Page 0 (default): Safe to Spend with Tax reserve + Safety buffer pills
/// Page 1: Total Balance with Income + Expenses pills
/// Page 2: Monthly Budget with Reserves + Bills pills
class DashboardHeroCarouselCard extends StatefulWidget {
  final double safeToSpend;
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final double taxReserve;
  final double safetyBuffer;
  final String locale;
  final String symbol;
  final String currencyCode;
  final VoidCallback? onWalletPressed;

  /// True if user has logged at least one income transaction (lifetime).
  /// When false, shows helper text explaining protections build from income.
  final bool hasLifetimeIncome;

  /// Optional smoothed budget snapshot for the third page.
  /// If null, the budget page shows "keep tracking" message.
  final SmoothedBudgetSnapshot? budgetSnapshot;

  /// Current month income for Page 2 (monthly context).
  final double currentMonthIncome;

  /// Current month expenses for Page 2 (monthly context).
  final double currentMonthExpense;

  const DashboardHeroCarouselCard({
    super.key,
    required this.safeToSpend,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.taxReserve,
    required this.safetyBuffer,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.onWalletPressed,
    this.hasLifetimeIncome = true,
    this.budgetSnapshot,
    this.currentMonthIncome = 0.0,
    this.currentMonthExpense = 0.0,
  });

  @override
  State<DashboardHeroCarouselCard> createState() =>
      _DashboardHeroCarouselCardState();
}

class _DashboardHeroCarouselCardState extends State<DashboardHeroCarouselCard> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatMoney(double amount) {
    return IncoreNumberFormatter.formatMoney(
      amount.abs(),
      locale: widget.locale,
      symbol: widget.symbol,
      currencyCode: widget.currencyCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surfaceGlass80,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
              border: Border.all(
                color: context.borderGlass60,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 236,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      children: [
                        _SafeToSpendPage(
                          safeToSpend: widget.safeToSpend,
                          taxReserve: widget.taxReserve,
                          safetyBuffer: widget.safetyBuffer,
                          currencyCode: widget.currencyCode,
                          formatMoney: _formatMoney,
                          onWalletPressed: widget.onWalletPressed,
                          theme: theme,
                          hasLifetimeIncome: widget.hasLifetimeIncome,
                        ),
                        _TotalBalancePage(
                          balance: widget.balance,
                          monthlyIncome: widget.currentMonthIncome,
                          monthlyExpense: widget.currentMonthExpense,
                          currencyCode: widget.currencyCode,
                          formatMoney: _formatMoney,
                          onWalletPressed: widget.onWalletPressed,
                          theme: theme,
                        ),
                        _StableWeeklyBudgetPage(
                          budgetSnapshot: widget.budgetSnapshot,
                          currentMonthSpending: widget.currentMonthExpense,
                          dayOfMonth: DateTime.now().day,
                          formatMoney: _formatMoney,
                          onWalletPressed: widget.onWalletPressed,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DotsIndicator(
                  currentIndex: _currentIndex,
                  count: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 0: Safe to Spend
class _SafeToSpendPage extends StatelessWidget {
  final double safeToSpend;
  final double taxReserve;
  final double safetyBuffer;
  final String currencyCode;
  final String Function(double) formatMoney;
  final VoidCallback? onWalletPressed;
  final ThemeData theme;
  final bool hasLifetimeIncome;

  const _SafeToSpendPage({
    required this.safeToSpend,
    required this.taxReserve,
    required this.safetyBuffer,
    required this.currencyCode,
    required this.formatMoney,
    required this.onWalletPressed,
    required this.theme,
    required this.hasLifetimeIncome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayAmount = safeToSpend < 0
        ? '- ${formatMoney(safeToSpend)}'
        : formatMoney(safeToSpend);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.safeToSpend,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.slate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _WalletIcon(onPressed: onWalletPressed),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayAmount,
            style: theme.textTheme.displaySmall?.copyWith(
              color: context.slate900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyCode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PillTile(
                  label: l10n.taxProtected,
                  value: formatMoney(taxReserve),
                  icon: Icons.shield_outlined,
                  backgroundColor: context.amber50,
                  borderColor: context.amber200,
                  textColor: context.amber700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillTile(
                  label: l10n.safetyProtected,
                  value: formatMoney(safetyBuffer),
                  icon: Icons.savings_outlined,
                  backgroundColor: context.blue50,
                  borderColor: context.borderSubtle,
                  textColor: context.blue600,
                ),
              ),
            ],
          ),
          // Helper line explaining these amounts are set aside
          const SizedBox(height: 10),
          Text(
            hasLifetimeIncome
                ? l10n.amountsAlreadySetAside
                : l10n.protectionsBuildAfterIncome,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.slate400,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 1: Total Balance (with monthly income/expense context)
class _TotalBalancePage extends StatelessWidget {
  final double balance;
  final double monthlyIncome;
  final double monthlyExpense;
  final String currencyCode;
  final String Function(double) formatMoney;
  final VoidCallback? onWalletPressed;
  final ThemeData theme;

  const _TotalBalancePage({
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.currencyCode,
    required this.formatMoney,
    required this.onWalletPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayAmount =
        balance < 0 ? '- ${formatMoney(balance)}' : formatMoney(balance);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalBalance,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.slate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _WalletIcon(onPressed: onWalletPressed),
            ],
          ),
          const SizedBox(height: 8),
          // Hero: Balance amount
          Text(
            displayAmount,
            style: theme.textTheme.displaySmall?.copyWith(
              color: context.slate900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          // Sublabel explaining scope
          Text(
            l10n.currentTotalBalance,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          // Section label for monthly context
          Text(
            l10n.thisMonth,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.slate400,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Pills: Income & Expenses (monthly)
          Row(
            children: [
              Expanded(
                child: _PillTile(
                  label: l10n.income,
                  value: formatMoney(monthlyIncome),
                  icon: Icons.trending_up,
                  backgroundColor: context.tealBg80,
                  borderColor: context.tealBorder50,
                  textColor: context.teal600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillTile(
                  label: l10n.expenses,
                  value: formatMoney(monthlyExpense),
                  icon: Icons.trending_down,
                  backgroundColor: context.roseBg80,
                  borderColor: context.roseBorder50,
                  textColor: context.rose600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Page 2: Stable Weekly Budget
class _StableWeeklyBudgetPage extends StatelessWidget {
  final SmoothedBudgetSnapshot? budgetSnapshot;
  final double currentMonthSpending;
  final int dayOfMonth;
  final String Function(double) formatMoney;
  final VoidCallback? onWalletPressed;
  final ThemeData theme;

  const _StableWeeklyBudgetPage({
    required this.budgetSnapshot,
    required this.currentMonthSpending,
    required this.dayOfMonth,
    required this.formatMoney,
    required this.onWalletPressed,
    required this.theme,
  });

  String _volatilityLevel(double cv, AppLocalizations l10n) {
    if (cv < 0.20) return l10n.levelLow;
    if (cv <= 0.40) return l10n.levelMedium;
    return l10n.levelHigh;
  }

  String _confidenceLevel(BudgetConfidence confidence, AppLocalizations l10n) {
    switch (confidence) {
      case BudgetConfidence.low:
        return l10n.levelLow;
      case BudgetConfidence.medium:
        return l10n.levelMedium;
      case BudgetConfidence.high:
        return l10n.levelHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // If no budget data or not enough data, show "keep tracking" message
    if (budgetSnapshot == null ||
        !budgetSnapshot!.hasEnoughData ||
        budgetSnapshot!.weeklySpendable <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.stableWeeklyBudgetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _WalletIcon(onPressed: onWalletPressed),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '—',
              style: theme.textTheme.displaySmall?.copyWith(
                color: context.slate900,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.budgetKeepTrackingStable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.slate400,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final budget = budgetSnapshot!;

    // Pacing calculation
    final expectedSpent = budget.dailySpendable * dayOfMonth;
    final ratio = expectedSpent > 0 ? currentMonthSpending / expectedSpent : 0.0;
    final progressValue = (ratio / 1.5).clamp(0.0, 1.0);

    // Determine pacing status
    final bool isOnTrack = ratio <= 1.0;
    final bool isSlightlyOver = ratio > 1.0 && ratio <= 1.2;

    Color pacingColor;
    String? pacingText; // null when on track (no label shown)
    if (isOnTrack) {
      pacingColor = context.teal600.withValues(alpha: 0.6);
      pacingText = null; // Don't show label when on track
    } else if (isSlightlyOver) {
      pacingColor = context.amber600.withValues(alpha: 0.7);
      pacingText = l10n.pacingSlightlyOver;
    } else {
      pacingColor = context.rose600; // Full opacity for over pace
      pacingText = l10n.pacingOver;
    }

    // Inline detail values
    final smoothedIncomeText = formatMoney(budget.smoothedMonthlyIncome);
    final volatilityText = _volatilityLevel(budget.incomeVolatility, l10n);
    final confidenceText = _confidenceLevel(budget.confidence, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.stableWeeklyBudgetTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _WalletIcon(onPressed: onWalletPressed),
            ],
          ),
          const SizedBox(height: 8),
          // Hero: Weekly amount with smaller /week suffix
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatMoney(budget.weeklySpendable),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: context.slate900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.perWeek,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle: Based on X months
          Text(
            l10n.basedOnMonths(budget.monthsOfIncomeData),
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Inline detail row (replaces boxed chips)
          _buildInlineDetailsRow(
            context: context,
            smoothedIncome: smoothedIncomeText,
            volatility: volatilityText,
            confidence: confidenceText,
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          // Weekly spending guide
          _buildSpendingGuide(
            context: context,
            l10n: l10n,
            progressValue: progressValue,
            pacingColor: pacingColor,
            pacingText: pacingText,
          ),
        ],
      ),
    );
  }

  /// Builds the inline details row with bullet separators.
  /// Uses Wrap to handle narrow screens gracefully.
  Widget _buildInlineDetailsRow({
    required BuildContext context,
    required String smoothedIncome,
    required String volatility,
    required String confidence,
    required AppLocalizations l10n,
  }) {
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: context.slate400,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    );

    final bulletStyle = theme.textTheme.bodySmall?.copyWith(
      color: context.slate300,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    );

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: [
        Text('${l10n.smoothedIncomeLabel} $smoothedIncome', style: textStyle),
        Text(' • ', style: bulletStyle),
        Text('${l10n.volatilityLabel} $volatility', style: textStyle),
        Text(' • ', style: bulletStyle),
        Text('${l10n.confidenceLabel} $confidence', style: textStyle),
      ],
    );
  }

  /// Builds the weekly spending guide with progress bar.
  /// Only shows status text when not on track.
  Widget _buildSpendingGuide({
    required BuildContext context,
    required AppLocalizations l10n,
    required double progressValue,
    required Color pacingColor,
    required String? pacingText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          l10n.weeklySpendingGuide,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.slate400,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        // Progress bar (thin, rounded)
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 5,
            backgroundColor: context.slate200,
            valueColor: AlwaysStoppedAnimation<Color>(pacingColor),
          ),
        ),
        // Status text (only when not on track)
        if (pacingText != null) ...[
          const SizedBox(height: 4),
          Text(
            pacingText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: pacingColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

/// Wallet icon box
class _WalletIcon extends StatelessWidget {
  final VoidCallback? onPressed;

  const _WalletIcon({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final iconContainer = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.blue50,
        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        size: 24,
        color: context.blue600,
      ),
    );

    if (onPressed != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
          child: iconContainer,
        ),
      );
    }

    return iconContainer;
  }
}

/// Pill tile widget for metrics
class _PillTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _PillTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots indicator for page position
class _DotsIndicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _DotsIndicator({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? context.blue600 : context.slate300,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
