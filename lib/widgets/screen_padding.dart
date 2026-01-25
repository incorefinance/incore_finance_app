import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable widget that applies consistent screen-level padding.
///
/// Uses [AppTheme.screenHorizontalPadding] for left/right margins
/// and optionally [AppTheme.screenTopPadding] for top spacing.
class ScreenPadding extends StatelessWidget {
  final Widget child;
  final bool includeTopPadding;
  final bool includeBottomPadding;
  final double? bottomPadding;

  const ScreenPadding({
    super.key,
    required this.child,
    this.includeTopPadding = true,
    this.includeBottomPadding = false,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.screenHorizontalPadding,
        includeTopPadding ? AppTheme.screenTopPadding : 0,
        AppTheme.screenHorizontalPadding,
        includeBottomPadding ? (bottomPadding ?? 0) : 0,
      ),
      child: child,
    );
  }
}
