import 'package:flutter/material.dart';

/// Navigation item configuration for bottom bar
enum BottomBarItem {
  dashboard,
  transactions,
  analytics,
  settings,
}

/// Custom bottom navigation bar widget for personal finance app
/// Implements bottom-heavy design strategy with thumb-reach optimization
/// Follows Material Design guidelines with platform-aware adaptations
class CustomBottomBar extends StatelessWidget {
  /// Currently selected navigation item
  final BottomBarItem currentItem;

  /// Callback when navigation item is tapped
  final ValueChanged<BottomBarItem> onItemSelected;

  /// Whether to show labels for all items (default: true)
  final bool showLabels;

  /// Custom background color (optional, uses theme if not provided)
  final Color? backgroundColor;

  /// Custom selected item color (optional, uses theme if not provided)
  final Color? selectedItemColor;

  /// Custom unselected item color (optional, uses theme if not provided)
  final Color? unselectedItemColor;

  const CustomBottomBar({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
    this.showLabels = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  /// Get navigation configuration for each item
  _NavigationItemConfig _getItemConfig(BottomBarItem item) {
    switch (item) {
      case BottomBarItem.dashboard:
        return _NavigationItemConfig(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Dashboard',
          route: '/dashboard-home',
        );
      case BottomBarItem.transactions:
        return _NavigationItemConfig(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Transactions',
          route: '/transactions-list',
        );
      case BottomBarItem.analytics:
        return _NavigationItemConfig(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: 'Analytics',
          route: '/analytics-dashboard',
        );
      case BottomBarItem.settings:
        return _NavigationItemConfig(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Settings',
          route: '/settings',
        );
    }
  }

  /// Handle navigation item tap with proper routing
  void _handleItemTap(BuildContext context, BottomBarItem item) {
    if (item == currentItem) return;

    final config = _getItemConfig(item);
    onItemSelected(item);

    // Navigate to the route with replacement to maintain clean navigation stack
    Navigator.pushReplacementNamed(context, config.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use custom colors or fall back to theme colors
    final bgColor = backgroundColor ??
        theme.bottomNavigationBarTheme.backgroundColor ??
        colorScheme.surface;
    final selectedColor = selectedItemColor ??
        theme.bottomNavigationBarTheme.selectedItemColor ??
        colorScheme.primary;
    final unselectedColor = unselectedItemColor ??
        theme.bottomNavigationBarTheme.unselectedItemColor ??
        colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: BottomBarItem.values.map((item) {
              final config = _getItemConfig(item);
              final isSelected = item == currentItem;

              return Expanded(
                child: _BottomBarItemWidget(
                  config: config,
                  isSelected: isSelected,
                  showLabel: showLabels,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _handleItemTap(context, item),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Internal widget for individual bottom bar items
class _BottomBarItemWidget extends StatelessWidget {
  final _NavigationItemConfig config;
  final bool isSelected;
  final bool showLabel;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _BottomBarItemWidget({
    required this.config,
    required this.isSelected,
    required this.showLabel,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? config.selectedIcon : config.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: selectedColor.withValues(alpha: 0.1),
        highlightColor: selectedColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with scale animation
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),

              if (showLabel) ...[
                const SizedBox(height: 4),
                // Label with fade animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                  child: Text(
                    config.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration class for navigation items
class _NavigationItemConfig {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _NavigationItemConfig({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
