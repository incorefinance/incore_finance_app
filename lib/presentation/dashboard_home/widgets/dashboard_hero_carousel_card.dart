import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Dashboard Hero Carousel Card - Revolut-style swipeable hero with two pages.
/// Page 0 (default): Safe to Spend with Tax reserve + Safety buffer pills
/// Page 1: Total Balance with Income + Expenses pills
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
              color: AppColors.surfaceGlass80Light,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
              border: Border.all(
                color: AppColors.borderGlass60Light,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: widget.hasLifetimeIncome ? 210 : 240,
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
                          totalIncome: widget.totalIncome,
                          totalExpense: widget.totalExpense,
                          currencyCode: widget.currencyCode,
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
                  count: 2,
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
                'Safe to spend',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.slate500,
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
              color: AppColors.slate900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyCode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PillTile(
                  label: 'Tax reserve',
                  value: formatMoney(taxReserve),
                  icon: Icons.shield_outlined,
                  backgroundColor: AppColors.amber50,
                  borderColor: AppColors.amber200,
                  textColor: AppColors.amber700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillTile(
                  label: 'Safety buffer',
                  value: formatMoney(safetyBuffer),
                  icon: Icons.savings_outlined,
                  backgroundColor: AppColors.blueBg50,
                  borderColor: AppColors.borderSubtle,
                  textColor: AppColors.blue600,
                ),
              ),
            ],
          ),
          // Helper line: only show when no lifetime income
          if (!hasLifetimeIncome) ...[
            const SizedBox(height: 12),
            Text(
              l10n.protectionsBuildAfterIncome,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate400,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Page 1: Total Balance
class _TotalBalancePage extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final String currencyCode;
  final String Function(double) formatMoney;
  final VoidCallback? onWalletPressed;
  final ThemeData theme;

  const _TotalBalancePage({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencyCode,
    required this.formatMoney,
    required this.onWalletPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final displayAmount =
        balance < 0 ? '- ${formatMoney(balance)}' : formatMoney(balance);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.slate500,
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
              color: AppColors.slate900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyCode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PillTile(
                  label: 'Income',
                  value: formatMoney(totalIncome),
                  icon: Icons.trending_up,
                  backgroundColor: AppColors.tealBg80,
                  borderColor: AppColors.tealBorder50,
                  textColor: AppColors.teal600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillTile(
                  label: 'Expenses',
                  value: formatMoney(totalExpense),
                  icon: Icons.trending_down,
                  backgroundColor: AppColors.roseBg80,
                  borderColor: AppColors.roseBorder50,
                  textColor: AppColors.rose600,
                ),
              ),
            ],
          ),
        ],
      ),
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
        color: AppColors.blueBg50,
        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
      ),
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        size: 24,
        color: AppColors.blue600,
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
            color: isActive ? AppColors.blue600 : AppColors.slate300,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
