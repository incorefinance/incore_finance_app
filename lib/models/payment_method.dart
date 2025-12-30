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
  static PaymentMethod? fromAny(String? value) {
    if (value == null) return null;

    final v = value.trim();
    if (v.isEmpty) return null;

    final normalized = v.toLowerCase();

    // dbValue match
    for (final m in PaymentMethod.values) {
      if (m.dbValue == normalized) return m;
    }

    // label match
    for (final m in PaymentMethod.values) {
      if (m.label.toLowerCase() == normalized) return m;
    }

    // common variants
    switch (normalized) {
      case 'bank transfer':
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'mbway':
      case 'mb way':
      case 'mb_way':
        return PaymentMethod.mbWay;
      case 'direct debit':
      case 'direct_debit':
        return PaymentMethod.directDebit;
      default:
        return PaymentMethod.other;
    }
  }

  // Keep the old method name your code calls
  static PaymentMethod? fromDbValue(String? value) => fromAny(value);
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
        return 'mb_way';
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
