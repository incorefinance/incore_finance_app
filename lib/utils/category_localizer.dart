import 'package:flutter/material.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:incore_finance/models/transaction_category.dart';

/// Returns a localized label for a TransactionCategory.
/// This allows category labels to update when the app language changes.
String getLocalizedCategoryLabel(BuildContext context, TransactionCategory? category) {
  if (category == null) return '';
  final l10n = AppLocalizations.of(context)!;

  switch (category) {
    // Income categories
    case TransactionCategory.revSales:
      return l10n.catSales;
    case TransactionCategory.revFreelance:
      return l10n.catFreelance;
    case TransactionCategory.revConsulting:
      return l10n.catConsulting;
    case TransactionCategory.revRetainers:
      return l10n.catRetainers;
    case TransactionCategory.revSubscriptions:
      return l10n.catSubscriptionsIncome;
    case TransactionCategory.revCommissions:
      return l10n.catCommissions;
    case TransactionCategory.revInterest:
      return l10n.catInterest;
    case TransactionCategory.revRefunds:
      return l10n.catRefundsIncome;
    case TransactionCategory.revOther:
      return l10n.catOtherIncome;

    // Expense categories
    case TransactionCategory.mktAds:
      return l10n.catAdvertising;
    case TransactionCategory.mktSoftware:
      return l10n.catSoftware;
    case TransactionCategory.mktSubs:
      return l10n.catSubscriptionsExpense;
    case TransactionCategory.opsEquipment:
      return l10n.catEquipment;
    case TransactionCategory.opsSupplies:
      return l10n.catSupplies;
    case TransactionCategory.proAccounting:
      return l10n.catAccounting;
    case TransactionCategory.proContractors:
      return l10n.catContractors;
    case TransactionCategory.travelGeneral:
      return l10n.catTravel;
    case TransactionCategory.travelMeals:
      return l10n.catMeals;
    case TransactionCategory.opsRent:
      return l10n.catRent;
    case TransactionCategory.opsInsurance:
      return l10n.catInsurance;
    case TransactionCategory.opsTaxes:
      return l10n.catTaxes;
    case TransactionCategory.opsFees:
      return l10n.catFees;
    case TransactionCategory.peopleSalary:
      return l10n.catSalaries;
    case TransactionCategory.peopleTraining:
      return l10n.catTraining;
    case TransactionCategory.otherExpense:
      return l10n.catOtherExpense;
  }
}
