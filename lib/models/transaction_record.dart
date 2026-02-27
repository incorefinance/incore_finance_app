// lib/models/transaction_record.dart

import '../utils/date_format_util.dart';

class TransactionRecord {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final String type;
  final DateTime date;
  final String? paymentMethod;
  final String? client;
  final String? recurringExpenseId;
  final DateTime? occurrenceDate;

  const TransactionRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    required this.type,
    required this.date,
    this.paymentMethod,
    this.client,
    this.recurringExpenseId,
    this.occurrenceDate,
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    final rawAmount = map['amount'];

    double parsedAmount;
    if (rawAmount is int) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    final dateValue = map['date'];
    DateTime parsedDate;
    if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else if (dateValue is DateTime) {
      parsedDate = dateValue;
    } else {
      parsedDate = DateTime.now();
    }

    // Parse occurrence_date if present
    final occDateValue = map['occurrence_date'];
    DateTime? parsedOccurrenceDate;
    if (occDateValue is String) {
      parsedOccurrenceDate = DateTime.tryParse(occDateValue);
    } else if (occDateValue is DateTime) {
      parsedOccurrenceDate = occDateValue;
    }

    return TransactionRecord(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      amount: parsedAmount,
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      date: parsedDate,
      paymentMethod: map['payment_method']?.toString(),
      client: map['client']?.toString(),
      recurringExpenseId: map['recurring_expense_id']?.toString(),
      occurrenceDate: parsedOccurrenceDate,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      // IMPORTANT: this must match Supabase -> column name is `client`
      'client': client,
    };

    // Only include recurring fields if set (for auto-posted transactions)
    if (recurringExpenseId != null) {
      map['recurring_expense_id'] = recurringExpenseId;
    }
    if (occurrenceDate != null) {
      map['occurrence_date'] = _formatDateOnly(occurrenceDate!);
    }

    return map;
  }

  /// Format date as YYYY-MM-DD for Supabase DATE column.
  static String _formatDateOnly(DateTime dt) => toIsoDateString(dt);
}
