import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:incore_finance/l10n/app_localizations.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';
import '../../../domain/safety_buffer/safety_buffer_snapshot.dart';
import '../../../domain/tax_shield/tax_shield_snapshot.dart';
import '../../../models/recurring_expense.dart';
import 'pressure_point_actions_sheet.dart';

/// Renders the Safety Buffer info row and an optional Pressure Point line.
///
/// Both elements appear between the InsightCard area and the Overview section.
/// The widget handles its own visibility: if [snapshot] is null the entire
/// section collapses to [SizedBox.shrink].
///
/// Converted to StatefulWidget solely to cache pressure point visibility and
/// only report changes via [onPressurePointVisibilityChanged].
class SafetyBufferSection extends StatefulWidget {
  final SafetyBufferSnapshot? snapshot;
  final TaxShieldSnapshot? taxShield;
  final List<RecurringExpense> activeRecurringExpenses;
  final String currencyLocale;
  final String currencySymbol;
  final bool isInsightCardVisible;
  final VoidCallback onReviewBillsTap;
  final VoidCallback? onTaxShieldTap;
  final Future<void> Function(List<String> expenseIds)? onPauseExpenses;
  final VoidCallback? onPressurePointActionsOpened;
  final ValueChanged<bool>? onPressurePointVisibilityChanged;

  const SafetyBufferSection({
    super.key,
    required this.snapshot,
    this.taxShield,
    required this.activeRecurringExpenses,
    required this.currencyLocale,
    required this.currencySymbol,
    required this.isInsightCardVisible,
    required this.onReviewBillsTap,
    this.onTaxShieldTap,
    this.onPauseExpenses,
    this.onPressurePointActionsOpened,
    this.onPressurePointVisibilityChanged,
  });

  @override
  State<SafetyBufferSection> createState() => _SafetyBufferSectionState();
}

class _SafetyBufferSectionState extends State<SafetyBufferSection> {
  bool? _lastReportedPressureVisible;

  @override
  Widget build(BuildContext context) {
    if (widget.snapshot == null) return const SizedBox.shrink();

    // Report pressure point visibility after frame completes (only on change).
    final isPressureVisible = _isPressurePointVisible();
    if (isPressureVisible != _lastReportedPressureVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastReportedPressureVisible = isPressureVisible;
        widget.onPressurePointVisibilityChanged?.call(isPressureVisible);
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSafetyBufferRow(context),
        _buildPressurePointLine(context),
      ],
    );
  }

  // ── Pressure point visibility check ───────────────────────

  bool _isPressurePointVisible() {
    if (widget.isInsightCardVisible) return false;
    final snap = widget.snapshot;
    if (snap == null) return false;
    final days = snap.bufferDays;
    if (days == null || days >= 45) return false;
    final now = DateTime.now();
    final dueTotals = _computeRecurringDueTotals(
      widget.activeRecurringExpenses,
      now,
    );
    return dueTotals.dueNext7 > 0;
  }

  // ── Safety buffer row ───────────────────────────────────────

  Widget _buildSafetyBufferRow(BuildContext context) {
    final snap = widget.snapshot!;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = snap.bufferDays;

    // Amber only when bufferDays is a concrete number < 45.
    // null ("Not enough data") stays neutral.
    final isAmber = days != null && days < 45;
    const amber = AppColors.warning;

    final bgColor = isAmber
        ? amber.withValues(alpha: 0.08)
        : colorScheme.surface;
    final borderColor = isAmber
        ? amber.withValues(alpha: 0.18)
        : colorScheme.outlineVariant.withValues(alpha: 0.30);
    final iconColor = isAmber ? amber : colorScheme.onSurfaceVariant;

    final primaryText = _primaryText(l10n, snap);
    final qualifiers = _qualifiers(l10n, snap);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.shield_outlined,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  qualifiers,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                _buildTaxShieldLine(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _primaryText(AppLocalizations l10n, SafetyBufferSnapshot snap) {
    final days = snap.bufferDays;
    final title = l10n.safetyBufferTitle;

    if (days == null) {
      return '$title: ${l10n.safetyBufferNotEnoughData}';
    }
    if (days == 0) {
      return '$title: ${l10n.safetyBufferDays(0)}';
    }

    if (days >= 7 && snap.bufferWeeks != null) {
      final weeks = snap.bufferWeeks!;
      final weeksStr = weeks == weeks.roundToDouble()
          ? weeks.toInt().toString()
          : weeks.toStringAsFixed(1);
      return '$title: ${l10n.safetyBufferDaysWithWeeks(days, weeksStr)}';
    }
    return '$title: ${l10n.safetyBufferDays(days)}';
  }

  String _qualifiers(AppLocalizations l10n, SafetyBufferSnapshot snap) {
    final parts = <String>[
      l10n.safetyBufferQualAfterReserveAndBills,
      if (snap.usedTwoMonths)
        l10n.safetyBufferQualBasedOnLastTwoMonths
      else
        l10n.safetyBufferQualBasedOnLastMonth,
    ];
    return parts.join(' · ');
  }

  // ── Tax shield line ────────────────────────────────────────

  Widget _buildTaxShieldLine(BuildContext context) {
    if (widget.taxShield == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ts = widget.taxShield!;

    final percent = (ts.taxShieldPercent * 100).round();
    final String text;
    if (ts.taxShieldReserved >= 10) {
      final currency = NumberFormat.currency(
        locale: widget.currencyLocale,
        symbol: widget.currencySymbol,
      );
      text = l10n.safetyBufferTaxReserveIncludedWithAmount(
        percent,
        currency.format(ts.taxShieldReserved),
      );
    } else {
      text = l10n.safetyBufferTaxReserveIncluded(percent);
    }

    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );

    final textWidget = Text(text, style: textStyle);

    if (widget.onTaxShieldTap != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: InkWell(
          onTap: widget.onTaxShieldTap,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: textWidget),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: textWidget,
    );
  }

  // ── Pressure point line ─────────────────────────────────────

  Widget _buildPressurePointLine(BuildContext context) {
    if (widget.isInsightCardVisible) return const SizedBox.shrink();

    final snap = widget.snapshot;
    if (snap == null) return const SizedBox.shrink();

    final days = snap.bufferDays;
    if (days == null || days >= 45) return const SizedBox.shrink();

    final now = DateTime.now();
    final dueTotals = _computeRecurringDueTotals(
      widget.activeRecurringExpenses,
      now,
    );
    if (dueTotals.dueNext7 <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(
      locale: widget.currencyLocale,
      symbol: widget.currencySymbol,
    );
    final formatted = currency.format(dueTotals.dueNext7);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const amber = AppColors.warning;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: amber.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.pressurePointHeadsUp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' · ${l10n.pressurePointDueNext7Days(formatted)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pressurePointOpeningBills),
                  duration: const Duration(seconds: 2),
                ),
              );
              widget.onReviewBillsTap();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                l10n.pressurePointReviewBills,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.onPauseExpenses != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _openActionsSheet(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: amber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Actions sheet ──────────────────────────────────────────

  void _openActionsSheet(BuildContext context) {
    widget.onPressurePointActionsOpened?.call();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PressurePointActionsSheet(
        activeExpenses: widget.activeRecurringExpenses,
        currencyLocale: widget.currencyLocale,
        currencySymbol: widget.currencySymbol,
        onReviewBills: widget.onReviewBillsTap,
        onPauseExpenses: widget.onPauseExpenses!,
      ),
    );
  }

  // ── Due-date calculation helpers ────────────────────────────

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static DateTime _nextDueDateForExpense(
      RecurringExpense expense, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final daysThisMonth = _daysInMonth(now.year, now.month);
    final clampedDay = expense.dueDay.clamp(1, daysThisMonth);
    final candidate = DateTime(now.year, now.month, clampedDay);

    if (!candidate.isBefore(today)) return candidate;

    // Roll to next month
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final daysNext = _daysInMonth(nextYear, nextMonth);
    final clampedNext = expense.dueDay.clamp(1, daysNext);
    return DateTime(nextYear, nextMonth, clampedNext);
  }

  static ({double dueNext7, double dueNext14}) _computeRecurringDueTotals(
    List<RecurringExpense> expenses,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final end7 =
        today.add(const Duration(days: 8)); // inclusive 7-day horizon
    final end14 =
        today.add(const Duration(days: 15)); // inclusive 14-day horizon
    double d7 = 0.0, d14 = 0.0;
    for (final e in expenses) {
      final due = _nextDueDateForExpense(e, now);
      if (!due.isBefore(today) && due.isBefore(end7)) {
        d7 += e.amount.abs();
        d14 += e.amount.abs();
      } else if (!due.isBefore(today) && due.isBefore(end14)) {
        d14 += e.amount.abs();
      }
    }
    return (dueNext7: d7, dueNext14: d14);
  }
}
