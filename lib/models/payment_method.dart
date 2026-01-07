enum PaymentMethod {
  cash,
  card,
  bankTransfer,
  mbWay,
  paypal,
  directDebit,
  other,
}

class PaymentMethodParser {
  /// Backward compatible parser that accepts:
  /// db values: "cash", "mb_way", "bank_transfer"
  /// labels: "Cash", "MB Way", "Bank Transfer"
  /// also tolerates: "Card", "card"
  static PaymentMethod? fromAny(String? value) {
    if (value == null) return null;

    final v = value.trim();
    if (v.isEmpty) return null;

    final lower = v.toLowerCase();

    // 1) Try exact dbValue match
    for (final m in PaymentMethod.values) {
      if (m.dbValue == lower) return m;
    }

    // 2) Try label match (case insensitive)
    for (final m in PaymentMethod.values) {
      if (m.label.toLowerCase() == lower) return m;
    }

    // 3) Extra tolerance for common legacy variants
    switch (lower.replaceAll(' ', '_')) {
      case 'banktransfer':
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'mbway':
      case 'mb_way':
        return PaymentMethod.mbWay;
      case 'directdebit':
      case 'direct_debit':
        return PaymentMethod.directDebit;
      default:
        return PaymentMethod.other;
    }
  }

  /// Kept for older call sites
  static PaymentMethod? fromDbValue(String? value) => fromAny(value);

  /// Kept for readability in UI parsing
  static PaymentMethod? fromLabel(String? value) => fromAny(value);
}

extension PaymentMethodX on PaymentMethod {
  String get dbValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.mbWay:
        return 'mbway';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.directDebit:
        return 'direct_debit';
      case PaymentMethod.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.mbWay:
        return 'MB Way';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.directDebit:
        return 'Direct Debit';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}
