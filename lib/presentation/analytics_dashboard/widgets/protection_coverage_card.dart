import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/protection_monthly_point.dart';
import '../../../models/protection_snapshot.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../theme/app_theme.dart';

/// Allocation type for expansion state.
enum _ProtectionType { tax, safety }

/// Protection Coverage Card for Analytics dashboard.
///
/// Displays two expandable pills:
/// - Tax reserve (amber styling)
/// - Safety buffer (blue styling)
///
/// On tap, expands to show sparkline + helper text.
/// Only one can be expanded at a time.
class ProtectionCoverageCard extends StatefulWidget {
  final double taxProtected;
  final double safetyProtected;
  final double avgMonthlyExpenses;
  final int monthsUsed;
  final ConfidenceLevel confidence;
  final String locale;
  final String symbol;
  final String currencyCode;

  /// Tax percentage from settings (e.g., 25 for 25%)
  final int taxPercent;

  /// Monthly series data for sparklines (both tax and safety)
  final List<ProtectionMonthlyPoint> monthlySeries;

  /// Number of months to display (must match RPC p_months)
  final int monthsCount;

  const ProtectionCoverageCard({
    super.key,
    required this.taxProtected,
    required this.safetyProtected,
    required this.avgMonthlyExpenses,
    required this.monthsUsed,
    required this.confidence,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.taxPercent = 25,
    this.monthlySeries = const [],
    this.monthsCount = 6,
  });

  @override
  State<ProtectionCoverageCard> createState() => _ProtectionCoverageCardState();
}

class _ProtectionCoverageCardState extends State<ProtectionCoverageCard> {
  _ProtectionType? _expandedType;

  /// Toggle state for Safety buffer view (Monthly vs Total)
  bool _safetyShowTotal = false;

  String _formatMoney(double amount) {
    return NumberFormat.currency(
      locale: widget.locale,
      symbol: widget.symbol,
      decimalDigits: 0,
    ).format(amount.abs());
  }

  void _toggleExpansion(_ProtectionType type) {
    setState(() {
      if (_expandedType == type) {
        _expandedType = null;
        _safetyShowTotal = false; // Reset toggle when collapsing
      } else {
        _expandedType = type;
        _safetyShowTotal = false; // Reset toggle when switching
      }
    });
  }

  void _toggleSafetyView(bool showTotal) {
    setState(() => _safetyShowTotal = showTotal);
  }

  /// Generate last N month keys in YYYY-MM format (UTC to match ledger)
  List<String> _generateMonthKeys(int months) {
    final now = DateTime.now().toUtc();
    final keys = <String>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime.utc(now.year, now.month - i, 1);
      keys.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
    return keys;
  }

  /// Get padded series for an allocation type (fills missing months with 0)
  List<double> _getPaddedSeriesForType(_ProtectionType type) {
    final allocationType = type == _ProtectionType.tax ? 'tax' : 'safety';
    final monthKeys = _generateMonthKeys(widget.monthsCount);

    // Build lookup map from existing data
    final dataMap = <String, double>{};
    for (final point in widget.monthlySeries) {
      if (point.allocationType == allocationType) {
        dataMap[point.monthKey] = point.netAmount;
      }
    }

    // Return padded series (0 for missing months)
    return monthKeys.map((key) => dataMap[key] ?? 0.0).toList();
  }

  /// Convert monthly net series to cumulative running total
  List<double> _toCumulative(List<double> monthly) {
    if (monthly.isEmpty) return [];
    final cumulative = <double>[];
    double runningTotal = 0.0;
    for (final value in monthly) {
      runningTotal += value;
      cumulative.add(runningTotal);
    }
    return cumulative;
  }

  /// Format coverage text with proper pluralization
  String _formatCoverage(AppLocalizations l10n) {
    if (widget.avgMonthlyExpenses <= 0) {
      return l10n.protectionKeepTrackingExpenses;
    }

    final coverageMonths = widget.safetyProtected / widget.avgMonthlyExpenses;

    if (coverageMonths < 1.0) {
      // Less than 1 month: show days only with ~ prefix
      final days = (coverageMonths * 30).round();
      return l10n.coverageApproxDays(days);
    }

    final months = coverageMonths.floor();
    var days = ((coverageMonths - months) * 30).round();

    // Handle day overflow
    if (days >= 30) {
      return l10n.coverageMonthsOnly(months + 1);
    }

    if (days == 0) {
      return l10n.coverageMonthsOnly(months);
    }

    // Months and days (handle singular/plural)
    if (months == 1) {
      return l10n.coverageOneMonthDays(days);
    }
    return l10n.coverageMonthsDays(months, days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
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
                // Title
                Text(
                  l10n.protectionCoverage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.slate600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Protection pills row
                Row(
                  children: [
                    // Tax reserve pill
                    Expanded(
                      child: _ExpandableProtectionPill(
                        label: l10n.taxReserve,
                        amount: _formatMoney(widget.taxProtected),
                        icon: Icons.shield_outlined,
                        backgroundColor: context.amber50,
                        borderColor: context.amber200,
                        textColor: context.amber700,
                        isExpanded: _expandedType == _ProtectionType.tax,
                        onTap: () => _toggleExpansion(_ProtectionType.tax),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Safety buffer pill
                    Expanded(
                      child: _ExpandableProtectionPill(
                        label: l10n.safetyBufferTitle,
                        amount: _formatMoney(widget.safetyProtected),
                        icon: Icons.savings_outlined,
                        backgroundColor: context.blue50,
                        borderColor: context.borderGlass60,
                        textColor: context.blue600,
                        isExpanded: _expandedType == _ProtectionType.safety,
                        onTap: () => _toggleExpansion(_ProtectionType.safety),
                      ),
                    ),
                  ],
                ),

                // Expanded section
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _expandedType != null
                      ? _buildExpandedSection(context, theme, l10n)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isTax = _expandedType == _ProtectionType.tax;
    final paddedSeries = _getPaddedSeriesForType(_expandedType!);

    // For safety, optionally convert to cumulative
    final seriesData = (!isTax && _safetyShowTotal)
        ? _toCumulative(paddedSeries)
        : paddedSeries;

    final sparklineColor = isTax ? context.amber600 : context.blue600;
    final hasData = paddedSeries.any((v) => v != 0);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: context.dividerGlass60, height: 1),
          const SizedBox(height: 16),

          // Title row with optional toggle for Safety
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTax ? l10n.taxReserve : l10n.safetyBufferTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.slate600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Toggle only for Safety, only if has data
              if (!isTax && hasData)
                _SafetyViewToggle(
                  showTotal: _safetyShowTotal,
                  onChanged: _toggleSafetyView,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Sparkline label
          Text(
            isTax
                ? l10n.sparklineMonthlyChange
                : (_safetyShowTotal
                    ? l10n.sparklineTotalOverTime
                    : l10n.sparklineMonthlyChange),
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Sparkline
          SizedBox(
            height: 44,
            width: double.infinity,
            child: !hasData
                ? Center(
                    child: Text(
                      l10n.protectionNoHistory,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.slate400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _SparklinePainter(
                      data: seriesData,
                      color: sparklineColor.withValues(alpha: 0.6),
                      strokeWidth: 2.0,
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Helper lines
          if (isTax)
            _buildTaxHelperLines(context, theme, l10n)
          else
            _buildSafetyHelperLines(context, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildTaxHelperLines(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.protectionBasedOnIncome,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.slate500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.protectionCurrentRate(widget.taxPercent),
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyHelperLines(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final coverageText = _formatCoverage(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: Explanation (varies by toggle)
        Text(
          _safetyShowTotal
              ? l10n.safetyBufferBalanceOverTime
              : l10n.safetyBufferBuildsWithIncome,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.slate500,
          ),
        ),
        const SizedBox(height: 4),
        // Line 2: Coverage
        Text(
          '${l10n.safetyBufferCoverageLabel} $coverageText',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.slate400,
          ),
        ),
      ],
    );
  }
}

/// Compact pill-styled segmented toggle for Monthly/Total view.
class _SafetyViewToggle extends StatelessWidget {
  final bool showTotal;
  final ValueChanged<bool> onChanged;

  const _SafetyViewToggle({
    required this.showTotal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: context.slate100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: l10n.toggleMonthly,
            isSelected: !showTotal,
            onTap: () => onChanged(false),
          ),
          _ToggleOption(
            label: l10n.toggleTotal,
            isSelected: showTotal,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.blue600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.slate500,
          ),
        ),
      ),
    );
  }
}

/// Expandable protection pill widget with tap and chevron.
class _ExpandableProtectionPill extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ExpandableProtectionPill({
    required this.label,
    required this.amount,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isExpanded ? textColor.withValues(alpha: 0.5) : borderColor,
              width: isExpanded ? 1.5 : 1,
            ),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for sparkline visualization.
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;

  _SparklinePainter({
    required this.data,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // If only one data point, draw a horizontal line
    if (data.length == 1) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      return;
    }

    // Calculate min/max for scaling
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);

    // Add padding if all values are the same
    if (maxVal == minVal) {
      minVal = minVal - 1;
      maxVal = maxVal + 1;
    }

    final range = maxVal - minVal;
    final padding = 4.0; // Vertical padding

    // Build path
    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = padding + (1 - normalizedY) * (size.height - 2 * padding);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw path
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    // Draw dots at each point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = padding + (1 - normalizedY) * (size.height - 2 * padding);

      canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
