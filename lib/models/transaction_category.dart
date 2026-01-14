enum TransactionCategory {
  // ======================
  // INCOME
  // ======================

  revSales(
    dbValue: 'rev_sales',
    label: 'Sales',
    iconName: 'trending_up',
    isIncome: true,
  ),

  revFreelance(
    dbValue: 'rev_freelance',
    label: 'Freelance',
    iconName: 'laptop',
    isIncome: true,
  ),

  revConsulting(
    dbValue: 'rev_consulting',
    label: 'Consulting',
    iconName: 'work',
    isIncome: true,
  ),

  revRetainers(
    dbValue: 'rev_retainers',
    label: 'Retainers',
    iconName: 'repeat',
    isIncome: true,
  ),

  revSubscriptions(
    dbValue: 'rev_subscriptions',
    label: 'Subscriptions',
    iconName: 'autorenew',
    isIncome: true,
  ),

  revCommissions(
    dbValue: 'rev_commissions',
    label: 'Commissions',
    iconName: 'percent',
    isIncome: true,
  ),

  revInterest(
    dbValue: 'rev_interest',
    label: 'Interest',
    iconName: 'savings',
    isIncome: true,
  ),

  revRefunds(
    dbValue: 'rev_refunds',
    label: 'Refunds',
    iconName: 'undo',
    isIncome: true,
  ),

  revOther(
    dbValue: 'rev_other',
    label: 'Other Income',
    iconName: 'add',
    isIncome: true,
  ),

  // ======================
  // EXPENSES (existing)
  // ======================

  mktAds(
    dbValue: 'mkt_ads',
    label: 'Advertising',
    iconName: 'campaign',
    isIncome: false,
  ),

  mktSoftware(
    dbValue: 'mkt_software',
    label: 'Software',
    iconName: 'apps',
    isIncome: false,
  ),

  mktSubs(
    dbValue: 'mkt_subs',
    label: 'Subscriptions',
    iconName: 'subscriptions',
    isIncome: false,
  ),

  opsEquipment(
    dbValue: 'ops_equipment',
    label: 'Equipment',
    iconName: 'inventory_2',
    isIncome: false,
  ),

  opsSupplies(
    dbValue: 'ops_supplies',
    label: 'Supplies',
    iconName: 'shopping_cart',
    isIncome: false,
  ),

  proAccounting(
    dbValue: 'pro_accounting',
    label: 'Accounting',
    iconName: 'account_balance',
    isIncome: false,
  ),

  proContractors(
    dbValue: 'pro_contractors',
    label: 'Contractors',
    iconName: 'engineering',
    isIncome: false,
  ),

  travelGeneral(
    dbValue: 'travel_general',
    label: 'Travel',
    iconName: 'flight',
    isIncome: false,
  ),

  travelMeals(
    dbValue: 'travel_meals',
    label: 'Meals',
    iconName: 'restaurant',
    isIncome: false,
  ),

  opsRent(
    dbValue: 'ops_rent',
    label: 'Rent',
    iconName: 'home',
    isIncome: false,
  ),

  opsInsurance(
    dbValue: 'ops_insurance',
    label: 'Insurance',
    iconName: 'shield',
    isIncome: false,
  ),

  opsTaxes(
    dbValue: 'ops_taxes',
    label: 'Taxes',
    iconName: 'request_quote',
    isIncome: false,
  ),

  opsFees(
    dbValue: 'ops_fees',
    label: 'Fees',
    iconName: 'receipt_long',
    isIncome: false,
  ),

  peopleSalary(
    dbValue: 'people_salary',
    label: 'Salaries',
    iconName: 'badge',
    isIncome: false,
  ),

  peopleTraining(
    dbValue: 'people_training',
    label: 'Training',
    iconName: 'school',
    isIncome: false,
  ),

  otherExpense(
    dbValue: 'other_expense',
    label: 'Other Expense',
    iconName: 'more_horiz',
    isIncome: false,
  );

  const TransactionCategory({
    required this.dbValue,
    required this.label,
    required this.iconName,
    required this.isIncome,
  });

  final String dbValue;
  final String label;
  final String iconName;
  final bool isIncome;

  static TransactionCategory? fromDbValue(String? value) {
    if (value == null) return null;

    return TransactionCategory.values.firstWhere(
      (c) => c.dbValue == value,
      orElse: () => TransactionCategory.otherExpense,
    );
  }
}
