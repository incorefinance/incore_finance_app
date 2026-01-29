import 'package:flutter/material.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:incore_finance/models/payment_method.dart';

/// Returns a localized label for a PaymentMethod.
/// This allows payment method labels to update when the app language changes.
String getLocalizedPaymentLabel(BuildContext context, PaymentMethod? method) {
  if (method == null) return '';
  final l10n = AppLocalizations.of(context)!;

  switch (method) {
    case PaymentMethod.cash:
      return l10n.cash;
    case PaymentMethod.card:
      return l10n.card;
    case PaymentMethod.bankTransfer:
      return l10n.bankTransfer;
    case PaymentMethod.mbWay:
      return l10n.payMbWay;
    case PaymentMethod.paypal:
      return l10n.payPaypal;
    case PaymentMethod.directDebit:
      return l10n.payDirectDebit;
    case PaymentMethod.other:
      return l10n.other;
  }
}
