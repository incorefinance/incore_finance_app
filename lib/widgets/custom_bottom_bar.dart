import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors_ext.dart';
import '../theme/app_theme.dart';

/// Clearance height for scrollable content to avoid being hidden behind the floating nav bar.
/// Use this in screens with CustomBottomBar as bottom padding/spacer.
const double kBottomNavClearance = 120;

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
    final selectedColor = context.blue600;
    final unselectedColor = context.slate400;

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
      fab: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // blue-500
              Color(0xFF4F46E5), // indigo-600
            ],
          ),
          boxShadow: AppShadows.fabLight,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onAddTransaction,
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withValues(alpha: 0.25),
            highlightColor: Colors.white.withValues(alpha: 0.10),
            child: const Center(
              child: Icon(
                Icons.add,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          navItem(BottomBarItem.dashboard),
          navItem(BottomBarItem.transactions),

          // Center slot reserved only on screens that actually show +
          const SizedBox(width: 72),

          navItem(BottomBarItem.analytics),
          navItem(BottomBarItem.settings),
        ],
      ),
    );
  }
}

class _BarShell extends StatelessWidget {
  final Widget child;
  final Widget? fab;

  const _BarShell({required this.child, this.fab});

  static const double _fabOverflow = 20; // FAB extends above pill
  static const double _pillHeight = 72;
  static const double _bottomInset = 24;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _fabOverflow + _pillHeight + _bottomInset,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, _bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            // Stack allows FAB to overflow outside ClipRRect
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Glass pill (with blur - clips its own contents)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppShadows.navLight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        height: _pillHeight,
                        decoration: BoxDecoration(
                          color: context.surfaceGlass90,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: context.borderGlass60,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
                // FAB positioned outside ClipRRect so it won't be clipped
                if (fab != null)
                  Positioned(
                    top: -18,
                    child: fab!,
                  ),
              ],
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Semantics(
              label: label,
              selected: isSelected,
              button: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
