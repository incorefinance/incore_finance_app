// lib/services/recurring_expenses_auto_poster.dart
//
// Automatically posts transactions for due recurring expenses.
import '../utils/date_format_util.dart';
// This service:
// - Calculates which recurring expense occurrences are due (<= today)
// - Creates transactions for each due occurrence
// - Uses a unique constraint for idempotency (no duplicates)
// - Updates last_posted_occurrence_date to speed up future runs
//
// Usage:
//   final poster = RecurringExpensesAutoPoster();
//   final count = await poster.postDueRecurringExpenses(
//     userId: userId,
//     now: DateTime.now(),
//   );

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/logging/app_logger.dart';
import '../models/recurring_expense.dart';

class RecurringExpensesAutoPoster {
  final SupabaseClient _client;

  RecurringExpensesAutoPoster({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Posts due recurring expenses as transactions.
  /// Returns number of newly created transactions.
  ///
  /// [userId] - The authenticated user's ID
  /// [now] - Current date/time (device local time)
  /// [maxOccurrencesPerRun] - Cap on total occurrences processed per run (default: 6)
  Future<int> postDueRecurringExpenses({
    required String userId,
    required DateTime now,
    int maxOccurrencesPerRun = 6,
  }) async {
    // Use device local time - users are in Lisbon, app runs on open
    final today = DateTime(now.year, now.month, now.day);

    // 1. Load active recurring expenses
    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true);

    final expenses = (response as List)
        .whereType<Map<String, dynamic>>()
        .map(RecurringExpense.fromMap)
        .toList();

    if (expenses.isEmpty) return 0;

    // 2. Calculate due occurrences for each expense
    final allOccurrences = <_OccurrenceToPost>[];

    for (final expense in expenses) {
      DateTime startDate;

      if (expense.lastPostedOccurrenceDate != null) {
        // Already posted before -> start from next month after last posted
        startDate = _nextMonthOccurrence(
          expense.lastPostedOccurrenceDate!,
          expense.dueDay,
        );
      } else {
        // Never posted -> calculate first valid occurrence
        startDate = _firstOccurrence(expense.createdAt, expense.dueDay);
      }

      var occDate = startDate;
      while (!occDate.isAfter(today)) {
        // <= today
        allOccurrences.add(_OccurrenceToPost(expense: expense, date: occDate));
        occDate = _nextMonthOccurrence(occDate, expense.dueDay);
      }
    }

    if (allOccurrences.isEmpty) return 0;

    // 3. Sort by date and cap to maxOccurrencesPerRun
    allOccurrences.sort((a, b) => a.date.compareTo(b.date));
    final toProcess = allOccurrences.take(maxOccurrencesPerRun).toList();

    // 4. Insert transactions with unique constraint handling
    int posted = 0;
    for (final occ in toProcess) {
      final payload = {
        'user_id': userId,
        'amount': occ.expense.amount,
        'description': occ.expense.name,
        'category': 'other_expense', // Matches TransactionCategory enum
        'type': 'expense', // Matches transaction_type enum
        'date': occ.date.toIso8601String(),
        'payment_method': 'bank_transfer', // Matches PaymentMethod enum
        'recurring_expense_id': occ.expense.id,
        'occurrence_date': _formatDateOnly(occ.date),
      };

      try {
        await _client.from('transactions').insert(payload);
        posted++; // Only count if insert succeeded
      } on PostgrestException catch (e) {
        // 23505 = unique_violation (already exists) -> skip silently
        if (e.code == '23505') {
          AppLogger.d(
            'Skipping duplicate recurring transaction: '
            '${occ.expense.name} for ${_formatDateOnly(occ.date)}',
          );
          continue;
        }
        rethrow;
      }
    }

    // 5. Update last_posted_occurrence_date for each expense
    final maxDates = <String, DateTime>{};
    for (final occ in toProcess) {
      final existing = maxDates[occ.expense.id];
      if (existing == null || occ.date.isAfter(existing)) {
        maxDates[occ.expense.id] = occ.date;
      }
    }

    for (final entry in maxDates.entries) {
      await _client
          .from('recurring_expenses')
          .update({'last_posted_occurrence_date': _formatDateOnly(entry.value)})
          .eq('id', entry.key)
          .eq('user_id', userId);
    }

    return posted;
  }

  /// Get occurrence date for a given month, clamping to last day if needed.
  /// Example: dueDay=31 in February -> Feb 28/29
  DateTime _getOccurrenceDate(int year, int month, int dueDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final actualDay = dueDay.clamp(1, lastDay);
    return DateTime(year, month, actualDay);
  }

  /// Get next month's occurrence from a given date.
  DateTime _nextMonthOccurrence(DateTime from, int dueDay) {
    final nextMonth = from.month == 12
        ? DateTime(from.year + 1, 1, 1)
        : DateTime(from.year, from.month + 1, 1);
    return _getOccurrenceDate(nextMonth.year, nextMonth.month, dueDay);
  }

  /// Determines the first valid occurrence for a newly created recurring expense.
  /// Prevents instant backposting for bills created late in the month.
  ///
  /// Rule:
  /// - If created on or before this month's due date -> first occurrence is this month
  /// - If created after this month's due date -> first occurrence is next month
  DateTime _firstOccurrence(DateTime createdAt, int dueDay) {
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final thisMonthDue =
        _getOccurrenceDate(createdDate.year, createdDate.month, dueDay);

    if (!createdDate.isAfter(thisMonthDue)) {
      // Created on or before due date -> this month is first occurrence
      return thisMonthDue;
    } else {
      // Created after due date -> next month is first occurrence
      return _nextMonthOccurrence(thisMonthDue, dueDay);
    }
  }

  /// Format date as YYYY-MM-DD for Supabase DATE column.
  String _formatDateOnly(DateTime dt) => toIsoDateString(dt);
}

/// Internal class to hold an occurrence to be posted.
class _OccurrenceToPost {
  final RecurringExpense expense;
  final DateTime date;

  _OccurrenceToPost({required this.expense, required this.date});
}
