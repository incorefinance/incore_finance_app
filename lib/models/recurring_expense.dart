// lib/models/recurring_expense.dart
//
// Data model for recurring expenses.
// MVP: Monthly frequency only (implicit, no frequency field).
//
// Due day rule (documented here, implemented in short-term pressure logic):
// - due_day is stored as 1-31
// - When calculating next due date, clamp to last day of month
// - Example: due_day=31 in February -> Feb 28 or 29
// - Example: due_day=31 in April -> April 30

class RecurringExpense {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final int dueDay;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastPostedOccurrenceDate;

  const RecurringExpense({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.isActive,
    required this.createdAt,
    this.lastPostedOccurrenceDate,
  });

  /// Creates a RecurringExpense from a Supabase row map.
  /// Handles various input types robustly.
  factory RecurringExpense.fromMap(Map<String, dynamic> map) {
    // Parse amount (handles int, num, String)
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

    // Parse due_day (handles int, num, String)
    final rawDueDay = map['due_day'];
    int parsedDueDay;
    if (rawDueDay is int) {
      parsedDueDay = rawDueDay;
    } else if (rawDueDay is num) {
      parsedDueDay = rawDueDay.toInt();
    } else if (rawDueDay is String) {
      parsedDueDay = int.tryParse(rawDueDay) ?? 1;
    } else {
      parsedDueDay = 1;
    }
    // Clamp to valid range
    parsedDueDay = parsedDueDay.clamp(1, 31);

    // Parse is_active (handles bool, int, String)
    final rawIsActive = map['is_active'];
    bool parsedIsActive;
    if (rawIsActive is bool) {
      parsedIsActive = rawIsActive;
    } else if (rawIsActive is int) {
      parsedIsActive = rawIsActive != 0;
    } else if (rawIsActive is String) {
      parsedIsActive = rawIsActive.toLowerCase() == 'true' || rawIsActive == '1';
    } else {
      parsedIsActive = true;
    }

    // Parse created_at (handles String, DateTime)
    final rawCreatedAt = map['created_at'];
    DateTime parsedCreatedAt;
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // Parse last_posted_occurrence_date (handles String, DateTime)
    final rawLastPosted = map['last_posted_occurrence_date'];
    DateTime? parsedLastPosted;
    if (rawLastPosted is String) {
      parsedLastPosted = DateTime.tryParse(rawLastPosted);
    } else if (rawLastPosted is DateTime) {
      parsedLastPosted = rawLastPosted;
    }

    return RecurringExpense(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      amount: parsedAmount,
      dueDay: parsedDueDay,
      isActive: parsedIsActive,
      createdAt: parsedCreatedAt,
      lastPostedOccurrenceDate: parsedLastPosted,
    );
  }

  /// Converts this RecurringExpense to a map for Supabase insert/update.
  /// Note: id and created_at are typically handled by the database.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'due_day': dueDay,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };

    if (lastPostedOccurrenceDate != null) {
      map['last_posted_occurrence_date'] = _formatDateOnly(lastPostedOccurrenceDate!);
    }

    return map;
  }

  /// Format date as YYYY-MM-DD for Supabase DATE column.
  static String _formatDateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Creates a copy with optional field overrides.
  RecurringExpense copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    int? dueDay,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastPostedOccurrenceDate,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastPostedOccurrenceDate: lastPostedOccurrenceDate ?? this.lastPostedOccurrenceDate,
    );
  }

  @override
  String toString() {
    return 'RecurringExpense(id: $id, name: $name, amount: $amount, dueDay: $dueDay, isActive: $isActive, lastPosted: $lastPostedOccurrenceDate)';
  }
}
