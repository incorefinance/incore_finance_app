import 'package:flutter/material.dart';

enum BottomBarItem {
  dashboard,
  transactions,
  analytics,
  settings,
}

class CustomBottomBar extends StatelessWidget {
  final BottomBarItem currentItem;
  final ValueChanged<BottomBarItem> onItemSelected;

  // If null, the center slot is not rendered at all (no gap).
  final VoidCallback? onAddTransaction;

  const CustomBottomBar({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
    this.onAddTransaction,
  });

  _NavConfig _config(BottomBarItem item) {
    switch (item) {
      case BottomBarItem.dashboard:
        return const _NavConfig(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: '/dashboard-home',
        );
      case BottomBarItem.transactions:
        return const _NavConfig(
          label: 'Transactions',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          route: '/transactions-list',
        );
      case BottomBarItem.analytics:
        return const _NavConfig(
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          route: '/analytics-gate',
        );
      case BottomBarItem.settings:
        return const _NavConfig(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          route: '/settings',
        );
    }
  }

  void _go(BuildContext context, BottomBarItem item) {
    if (item == currentItem) return;

    onItemSelected(item);

    final route = _config(item).route;
    Navigator.of(context, rootNavigator: true).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedColor = cs.primary;
    final unselectedColor = cs.onSurface.withValues(alpha: 0.65);

    final showCenterAdd =
      onAddTransaction != null &&
      (currentItem == BottomBarItem.dashboard ||
          currentItem == BottomBarItem.transactions);

    Widget navItem(BottomBarItem item) {
      final cfg = _config(item);
      final isSelected = item == currentItem;

      return Expanded(
        child: _BottomBarItemWidget(
          label: cfg.label,
          icon: isSelected ? cfg.selectedIcon : cfg.icon,
          isSelected: isSelected,
          selectedColor: selectedColor,
          unselectedColor: unselectedColor,
          onTap: () => _go(context, item),
        ),
      );
    }

    // 4 items only (no gap) when there is no center add button
    if (!showCenterAdd) {
      return _BarShell(
        child: Row(
          children: [
            navItem(BottomBarItem.dashboard),
            navItem(BottomBarItem.transactions),
            navItem(BottomBarItem.analytics),
            navItem(BottomBarItem.settings),
          ],
        ),
      );
    }

    // With center add button: render 2 items, a spacer slot, then 2 items.
    // The + button is overlaid so it "sits" on the bar.
    return _BarShell(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              navItem(BottomBarItem.dashboard),
              navItem(BottomBarItem.transactions),

              // Center slot reserved only on screens that actually show +
              const SizedBox(width: 72),

              navItem(BottomBarItem.analytics),
              navItem(BottomBarItem.settings),
            ],
          ),

          Positioned(
            top: -18, // raise it a bit above the bar
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: onAddTransaction,
                elevation: 6,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarShell extends StatelessWidget {
  final Widget child;

  const _BarShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BottomBarItemWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _BottomBarItemWidget({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: label,
                selected: isSelected,
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavConfig {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _NavConfig({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}
