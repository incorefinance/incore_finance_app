// lib/models/user_financial_baseline.dart
//
// Data model for user financial baseline (starting balance).
// This represents a stable, editable value that is NOT stored as a transaction.
// One row per user, managed in the user_financial_baseline table.

class UserFinancialBaseline {
  final String id;
  final String userId;
  final double startingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserFinancialBaseline({
    required this.id,
    required this.userId,
    required this.startingBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserFinancialBaseline from a Supabase row map.
  /// Handles various input types for numeric and datetime fields.
  factory UserFinancialBaseline.fromMap(Map<String, dynamic> map) {
    // Parse starting_balance (handles int, num, String, null)
    final rawBalance = map['starting_balance'];
    double parsedBalance;
    if (rawBalance is int) {
      parsedBalance = rawBalance.toDouble();
    } else if (rawBalance is double) {
      parsedBalance = rawBalance;
    } else if (rawBalance is num) {
      parsedBalance = rawBalance.toDouble();
    } else if (rawBalance is String) {
      parsedBalance = double.tryParse(rawBalance) ?? 0.0;
    } else {
      parsedBalance = 0.0;
    }

    // Parse created_at (handles String, DateTime, null)
    final rawCreatedAt = map['created_at'];
    DateTime parsedCreatedAt;
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // Parse updated_at (handles String, DateTime, null)
    final rawUpdatedAt = map['updated_at'];
    DateTime parsedUpdatedAt;
    if (rawUpdatedAt is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
    } else if (rawUpdatedAt is DateTime) {
      parsedUpdatedAt = rawUpdatedAt;
    } else {
      parsedUpdatedAt = DateTime.now();
    }

    return UserFinancialBaseline(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      startingBalance: parsedBalance,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Converts this UserFinancialBaseline to a map for Supabase insert/update.
  /// Note: id, created_at, and updated_at are typically handled by the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'starting_balance': startingBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy with specified fields replaced.
  UserFinancialBaseline copyWith({
    String? id,
    String? userId,
    double? startingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserFinancialBaseline(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startingBalance: startingBalance ?? this.startingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserFinancialBaseline('
        'id: $id, '
        'userId: $userId, '
        'startingBalance: $startingBalance, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserFinancialBaseline &&
        other.id == id &&
        other.userId == userId &&
        other.startingBalance == startingBalance &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        startingBalance.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
