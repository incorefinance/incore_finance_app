// lib/models/transaction_record.dart

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

    return TransactionRecord(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      amount: parsedAmount,
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      date: parsedDate,
      paymentMethod: map['payment_method']?.toString(),
      // Tolerant on reads: if you ever had client_name in old data, it still works.
      client: (map['client'] ?? map['client'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  }
}
