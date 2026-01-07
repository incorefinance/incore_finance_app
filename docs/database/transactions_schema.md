# Transactions Schema

This document describes the database schema, constraints, and design decisions for the `transactions` table.

It is the **source of truth** for how financial transactions are stored, validated, and enforced at the database level.

---

## Goals of the Schema

The transactions schema is designed to:

- Guarantee data integrity for financial records
- Prevent invalid combinations of transaction type and category
- Scale safely as new categories and payment methods are added
- Align 1:1 with Flutter domain models
- Avoid brittle or hardcoded check constraints

This is a production-grade schema, not a prototype.

---

## Table: public.transactions

### Core columns

- `id` (uuid, not null)  
  Primary key

- `user_id` (uuid, not null)  
  Owner of the transaction

- `date` (timestamptz, not null)  
  Effective transaction date

- `amount` (numeric, not null)  
  Absolute amount. Sign is inferred from `type`

- `type` (transaction_type enum, not null)  
  Indicates whether the transaction is income or expense

- `category` (transaction_category enum, not null)  
  Business category

- `payment_method` (text, nullable)  
  How the transaction was paid

- `description` (text, nullable)  
  Optional description

- `client` (text, nullable)  
  Optional client or counterparty

- `created_at` (timestamptz, not null)  
  Insert timestamp

---

## Enum: transaction_type

### Definition

sql
`create type public.transaction_type as enum (
  'income',
  'expense'
);`

### Purpose
- Enforces that every transaction is either income or expense
- Prevents invalid values such as:
        - "Income"
        - "EXPENSE"
        - NULL
- Matches Flutter logic exactly

#### Notes:
-This column was migrated from text to enum
-Existing constraints referencing text were dropped and recreated safely

## Enum: transaction_category
### Definition
`create type public.transaction_category as enum (
  -- Income
  'rev_sales',
  'rev_freelance',
  'rev_consulting',
  'rev_retainers',
  'rev_subscriptions',
  'rev_commissions',
  'rev_interest',
  'rev_refunds',
  'rev_other',

  -- Expenses
  'mkt_ads',
  'mkt_software',
  'mkt_subs',
  'ops_equipment',
  'ops_supplies',
  'pro_accounting',
  'pro_contractors',
  'travel_general',
  'travel_meals',
  'ops_rent',
  'ops_insurance',
  'ops_taxes',
  'ops_fees',
  'people_salary',
  'people_training',
  'other_expense'
);

## Purpose
- Enforces only valid business categories
- Guarantees 1:1 mapping with Flutter’s TransactionCategory enum
- Avoids fragile CHECK (category IN (...)) constraints

## Design decision
A Postgres enum was chosen instead of a check constraint because:
- It scales cleanly as categories grow
- Adding a new category is explicit and safe
- The database remains self-documenting

### Cross-field integrity constraint
## Constraint: transactions_type_matches_category
check (
  (type = 'income' and category::text like 'rev_%')
  or
  (type = 'expense' and category::text not like 'rev_%')
);

## What this enforces
- Income transactions must use categories starting with rev_
- Expense transactions must not use rev_ categories

## Why this exists
This prevents invalid financial states such as:
- Income recorded with an expense category
- Expense recorded as revenue
- Silent corruption of analytics

This rule scales automatically as new categories are added.

### Flutter alignment
## Flutter enum: TransactionCategory
The Flutter enum defines:
- dbValue → value stored in the database
- label → UI text
- iconName → UI icon
- isIncome → business logic

The database enum values must always match dbValue exactly.

## Single source of truth rule
Flutter controls:
- UX
- business intent

Database enforces:
- correctness
- integrity

### Adding a new category (required procedure)
Whenever a new category is added in Flutter:

## Step 1: Add it to TransactionCategory (Flutter)

revAffiliate(
  dbValue: 'rev_affiliate',
  label: 'Affiliate',
  iconName: 'link',
  isIncome: true,
),

## Step 2: Add it to the DB enum
alter type public.transaction_category
add value if not exists 'rev_affiliate';

## Step 3: No other changes required
- Cross-field constraint automatically applies
- UI and DB remain aligned

### Migration notes
## Why constraints were dropped during migration
When converting columns from text to enum:
- Existing constraints comparing type = 'income'::text become invalid
- These constraints must be dropped temporarily
- After conversion, constraints are recreated using enum-safe comparisons

This is expected Postgres behavior and was handled deliberately.