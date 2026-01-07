# Payment Method Schema

This document describes how payment methods are represented and enforced for the `transactions.payment_method` column.

The goal is to guarantee that payment method values are consistent across the database and Flutter, while remaining tolerant of legacy values during reads.

---

## Goals

This schema is designed to:

• Prevent inconsistent payment method strings such as "Card", "Cash", "Bank Transfer", or "mb_way"  
• Provide a single canonical set of values for analytics and reporting  
• Scale safely as new payment methods are added  
• Align 1 to 1 with Flutter’s `PaymentMethod` model  
• Allow backward compatible parsing for legacy data

---

## Column

Column: `public.transactions.payment_method`  
Type: `public.payment_method` enum

This column is enforced as a Postgres enum to prevent invalid or inconsistent values.

---

## Enum: public.payment_method

### Canonical values

The database stores only canonical values. These values must match Flutter `PaymentMethod.dbValue` exactly.

Canonical set:

• `cash`  
• `card`  
• `bank_transfer`  
• `mbway`  
• `paypal`  
• `direct_debit`  
• `other`

### Design decision

An enum was chosen instead of a text column plus checks because:

• It prevents silent data corruption  
• It guarantees consistent values for analytics  
• Adding a new method is explicit and auditable  
• It keeps the schema self documenting

---

## Legacy compatibility

Legacy values may exist from older UI versions or manual data entry, for example:

• `Cash`  
• `Card`  
• `Bank Transfer`  
• `mb_way`

These legacy values must not be stored going forward.

The system follows a strict rule:

• Reads are tolerant  
• Writes are strict

---

## Flutter alignment

Flutter uses:

• `enum PaymentMethod`  
• `PaymentMethodParser.fromAny` for tolerant parsing  
• `PaymentMethod.dbValue` as the canonical stored value

### Canonical storage rule

All writes to Supabase must use:

`paymentMethod.dbValue`

This ensures the database only receives enum safe canonical values.

### Backward compatible parsing rule

`PaymentMethodParser.fromAny` may accept legacy input strings and map them to the correct enum value, but it must not cause legacy strings to be written back to the database.

---

## Adding a new payment method

When adding a new payment method, the order is mandatory.

### Step 1: Add the value to the database enum

`alter type public.payment_method
add value if not exists 'apple_pay';`

### Step 2: Add the value to Flutter PaymentMethod enum

Add a new enum member and update dbValue and label.

### Step 3: Update UI selector

Ensure the selector writes dbValue and not label text.

### Summary
This schema ensures:
- Payment methods are consistent and analytics safe
- Flutter and database remain aligned
- Legacy values can be read safely without being re introduced
- The system scales cleanly as new payment methods are added

If anything conflicts with this document, the schema and canonical values win.