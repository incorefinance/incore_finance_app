import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different screen contexts
enum AppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with back button and title
  detail,

  /// Transparent app bar for scrollable content
  transparent,
}

/// Custom app bar widget for personal finance app
/// Implements clean, professional interface with contextual actions
/// Follows Material Design with platform-aware adaptations
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title text
  final String? title;

  /// App bar variant type
  final AppBarVariant variant;

  /// Leading widget (typically back button or menu icon)
  final Widget? leading;

  /// Action widgets displayed on the right side
  final List<Widget>? actions;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Custom background color (optional, uses theme if not provided)
  final Color? backgroundColor;

  /// Custom foreground color for text and icons
  final Color? foregroundColor;

  /// Elevation of the app bar
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Search query callback for search variant
  final ValueChanged<String>? onSearchChanged;

  /// Search submit callback for search variant
  final ValueChanged<String>? onSearchSubmitted;

  /// Search hint text
  final String searchHint;

  /// Bottom widget (typically TabBar)
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = AppBarVariant.standard,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchHint = 'Search transactions...',
    this.bottom,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  /// Build standard app bar
  Widget _buildStandardAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  /// Build search app bar with integrated search field
  Widget _buildSearchAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
      title: TextField(
        autofocus: true,
        onChanged: onSearchChanged,
        onSubmitted: onSearchSubmitted,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: foregroundColor ?? theme.appBarTheme.foregroundColor,
        ),
        decoration: InputDecoration(
          hintText: searchHint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: (foregroundColor ??
                    theme.appBarTheme.foregroundColor ??
                    colorScheme.onSurface)
                .withValues(alpha: 0.6),
          ),
        ),
      ),
      actions: actions ??
          [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  /// Build detail app bar with back button
  Widget _buildDetailAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
      title: title != null ? Text(title!) : null,
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  /// Build transparent app bar for scrollable content
  Widget _buildTransparentAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case AppBarVariant.standard:
        return _buildStandardAppBar(context, theme, colorScheme);
      case AppBarVariant.search:
        return _buildSearchAppBar(context, theme, colorScheme);
      case AppBarVariant.detail:
        return _buildDetailAppBar(context, theme, colorScheme);
      case AppBarVariant.transparent:
        return _buildTransparentAppBar(context, theme, colorScheme);
    }
  }
}

/// Custom sliver app bar for scrollable content with collapse effect
class CustomSliverAppBar extends StatelessWidget {
  /// App bar title text
  final String title;

  /// Expanded height when not collapsed
  final double expandedHeight;

  /// Whether the app bar should float
  final bool floating;

  /// Whether the app bar should pin when scrolled
  final bool pinned;

  /// Whether the app bar should snap
  final bool snap;

  /// Leading widget
  final Widget? leading;

  /// Action widgets
  final List<Widget>? actions;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom foreground color
  final Color? foregroundColor;

  /// Flexible space widget (displayed in expanded area)
  final Widget? flexibleSpace;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.expandedHeight = 200.0,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      flexibleSpace: flexibleSpace ??
          FlexibleSpaceBar(
            title: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foregroundColor ?? theme.appBarTheme.foregroundColor,
              ),
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundColor ??
                        theme.appBarTheme.backgroundColor ??
                        colorScheme.surface,
                    (backgroundColor ??
                            theme.appBarTheme.backgroundColor ??
                            colorScheme.surface)
                        .withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
