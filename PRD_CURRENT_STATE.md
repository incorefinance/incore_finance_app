# PRD_CURRENT_STATE

This document describes the current, implemented product behavior in the codebase. It is a code-based PRD (what exists now), not a roadmap.

---

## 1) Product Summary

Incore Finance is a Flutter mobile app that supports:
- Email/password authentication via Supabase.
- A linear onboarding flow that captures currency, income type, starting balance, and recurring expenses.
- Core finance workflows: add/edit transactions, view transaction history, manage recurring expenses.
- A dashboard with high-level KPIs and safety buffer.
- An analytics area with charts, breakdowns, interpretations, and insights (premium gated).
- Settings for account info, plan management, currency/language, and export gating.

Primary data sources:
- Supabase tables: `transactions`, `recurring_expenses`, `user_financial_baseline`, `user_onboarding_status`, `usage_metrics`.
- Local settings: SharedPreferences (language, tax_shield_percent, UI toggles).

---

## 2) Navigation + Routes

Defined in `lib/routes/app_routes.dart`.

Routes:
- `/` StartupScreen
- `/auth` AuthScreen
- `/email-verification` EmailVerificationScreen
- `/forgot-password` ForgotPasswordScreen
- `/reset-password` ResetPasswordScreen
- `/auth-guard-error` AuthGuardErrorScreen
- `/onboarding` OnboardingFlow
- `/dashboard-home` DashboardHome
- `/transactions-list` TransactionsList
- `/add-transaction` AddTransaction
- `/recurring-expenses` RecurringExpenses
- `/analytics-gate` AnalyticsGateScreen
- `/analytics-dashboard` AnalyticsDashboard
- `/settings` Settings
- `/subscription` SubscriptionScreen

---

## 3) Data Models and Definitions

### 3.1 TransactionRecord
File: `lib/models/transaction_record.dart`

Fields:
- id, userId
- amount (double)
- description (string)
- category (string, db value)
- type (string: 'income' or 'expense')
- date (DateTime)
- paymentMethod (string, db value)
- client (string, optional)
- recurringExpenseId (string, optional)
- occurrenceDate (DateTime, optional)

Parsing rules:
- amount accepts int/num/string, falls back to 0.
- date accepts string/DateTime, defaults to now.
- occurrence_date parsed if present.

### 3.2 TransactionCategory
File: `lib/models/transaction_category.dart`

Income categories (dbValue -> label):
- rev_sales -> Sales
- rev_freelance -> Freelance
- rev_consulting -> Consulting
- rev_retainers -> Retainers
- rev_subscriptions -> Subscriptions
- rev_commissions -> Commissions
- rev_interest -> Interest
- rev_refunds -> Refunds
- rev_other -> Other Income

Expense categories (dbValue -> label):
- mkt_ads -> Advertising
- mkt_software -> Software
- mkt_subs -> Subscriptions
- ops_equipment -> Equipment
- ops_supplies -> Supplies
- pro_accounting -> Accounting
- pro_contractors -> Contractors
- travel_general -> Travel
- travel_meals -> Meals
- ops_rent -> Rent
- ops_insurance -> Insurance
- ops_taxes -> Taxes
- ops_fees -> Fees
- people_salary -> Salaries
- people_training -> Training
- other_expense -> Other Expense

Each category includes iconName and isIncome.

### 3.3 PaymentMethod
File: `lib/models/payment_method.dart`

Enum values:
- cash, card, bankTransfer, mbWay, paypal, directDebit, other

DB values:
- cash, card, bank_transfer, mbway, paypal, direct_debit, other

Parser accepts db values, labels, and common variants.

### 3.4 RecurringExpense
File: `lib/models/recurring_expense.dart`

Fields:
- id, userId, name
- amount (double)
- dueDay (1-31)
- isActive (bool)
- createdAt
- lastPostedOccurrenceDate (optional)

Due-day rules:
- Due day is clamped to last day of month when calculating occurrences.

### 3.5 UserFinancialBaseline
File: `lib/models/user_financial_baseline.dart`

- startingBalance: double (can be negative)

### 3.6 IncomeType
File: `lib/domain/onboarding/income_type.dart`

Values:
- fixed
- variable
- mixed

Used for missing income severity.

---

## 4) Auth + Session Management

### 4.1 StartupScreen
File: `lib/presentation/startup/startup_screen.dart`

Behavior:
- If no authenticated user after 500ms, show AuthForm.
- If signed in, route:
  - If email not verified -> EmailVerificationScreen.
  - If onboarding complete -> DashboardHome.
  - Else -> OnboardingFlow.
- Uses Auth state listener for sign-in/out events.
- Resets Superwall identity on sign-out.

### 4.2 AuthForm
File: `lib/presentation/auth/widgets/auth_form.dart`

Modes:
- Sign in and Sign up (toggle).

Validation:
- Email must include '@'.
- Password policy enforced on signup:
  - minLength = 12
  - maxLength = 128
  - no null or newline

Sign in:
- `supabase.auth.signInWithPassword`
- StartupScreen handles navigation via auth listener.

Sign up:
- `supabase.auth.signUp`
- If session returned: do not navigate (StartupScreen handles).
- If email confirmation required: navigate to EmailVerificationScreen with email argument.

### 4.3 Password Strength Indicator
File: `lib/presentation/auth/widgets/password_strength_indicator.dart`

- Uses zxcvbn for advisory strength scoring.
- Displays policy requirement (min length) and strength meter.

### 4.4 Forgot Password
File: `lib/presentation/auth/forgot_password_screen.dart`

- Sends reset email via `resetPasswordForEmail`.
- Uses redirect URI: `incore-dev://auth-callback`.
- Does not reveal if email exists (security).
- Rate limit errors show a friendly warning.

### 4.5 Reset Password
File: `lib/presentation/auth/reset_password_screen.dart`

- Requires valid recovery session.
- Validates new password with policy.
- Updates via `supabase.auth.updateUser`.
- Success -> back to StartupScreen.

### 4.6 Email Verification
File: `lib/presentation/auth/email_verification_screen.dart`

- 60-second resend cooldown stored in SharedPreferences.
- Resend uses `supabase.auth.resend(type: OtpType.signup)`.
- Manual refresh uses `supabase.auth.refreshSession`.
- Routes to onboarding or dashboard once verified.

### 4.7 AuthGuard Error Screen
File: `lib/presentation/auth/auth_guard_error_screen.dart`

- Used for unrecoverable auth/session issues.
- Sign out and route back to startup.

---

## 5) Onboarding Flow

File: `lib/presentation/onboarding/onboarding_flow.dart`

Steps (linear):
1) Welcome
2) Currency (mandatory)
3) Income type (mandatory)
4) Starting balance (optional)
5) Recurring expenses (optional)
6) Done

Completion:
- `OnboardingService.setOnboardingComplete()`
- Presents paywall `post_onboarding` (subject to cooldown)
- Routes to DashboardHome

### 5.1 Currency Selection
File: `lib/presentation/onboarding/onboarding_currency_screen.dart`

- Must select one of USD, BRL, EUR, GBP.
- Saves via `UserSettingsService.saveCurrencyCode`.

### 5.2 Income Setup
File: `lib/presentation/onboarding/income_setup_screen.dart`

- Required: income type (fixed/variable/mixed)
- Optional: monthly estimate (double)
- Saves to `user_onboarding_status` via UserIncomeRepository.

### 5.3 Starting Balance
File: `lib/presentation/onboarding/onboarding_starting_balance_screen.dart`

- Optional numeric input.
- User can toggle positive/negative.
- Saved via `UserFinancialBaselineRepository.upsertStartingBalance`.

### 5.4 Recurring Expenses
File: `lib/presentation/onboarding/onboarding_recurring_expenses_screen.dart`

- Optional step using existing recurring expense dialog.

---

## 6) Dashboard Home

File: `lib/presentation/dashboard_home/dashboard_home.dart`

Primary blocks (in order):
1) Total Balance Card
2) Safety Buffer Card
3) Monthly Profit Card
4) Upcoming Bills

### 6.1 Total Balance
File: `lib/presentation/dashboard_home/widgets/total_balance_card.dart`

Metrics:
- Total Income = sum of all income transactions.
- Total Expense = sum of all expense transactions.
- Cash Balance = starting_balance + total_income - total_expense.

Display:
- Balance is shown as negative if < 0.
- Income and Expense pills show formatted totals.

### 6.2 Monthly Profit
File: `lib/presentation/dashboard_home/widgets/monthly_profit_card.dart`

Current month:
- currentMonthIncome = sum income in current calendar month.
- currentMonthExpense = sum expense in current calendar month.
- currentProfit = income - expense.

Previous month:
- prevProfit = prevIncome - prevExpense.
- percentChange = ((currentProfit - prevProfit) / prevProfit) * 100, only if prevProfit != 0.

Trend badge visibility:
- hidden if no previous month data.
- hidden if prevProfit == 0.
- hidden if sign flips (profit to loss or loss to profit).
- shown otherwise.

### 6.3 Safety Buffer (Dashboard)
Uses TaxShieldCalculator and SafetyBufferCalculator (see Section 12).

### 6.4 Upcoming Bills
File: `lib/presentation/dashboard_home/widgets/upcoming_bills_card.dart`

- Shows up to 3 active recurring expenses.
- Computes next due date based on dueDay with month clamping.
- Due text:
  - today / tomorrow / in N days (<=7) / due on day D

If none, shows add/manage CTA placeholders.

---

## 7) Transactions List

File: `lib/presentation/transactions_list/transactions_list.dart`

### 7.1 Data Loading
- Loads all transactions via `TransactionsRepository.getTransactionsForCurrentUserTyped()`.
- List sorted by date descending.
- Grouped by month (MMMM yyyy) in UI.

### 7.2 Filters
Filters include:
- Search query (description or client contains query)
- Category
- Date range (today, last 7 days, this month, this year)
- Payment method
- Type (all/income/expense)

Date range logic:
- today: same day
- week: now - 7 days
- month: same month
- year: same year

### 7.3 Deletion with Undo
- Swipe delete triggers confirm dialog.
- If confirmed:
  - Item removed from list.
  - A pending delete entry is stored with 5 second timer.
  - Inline undo row appears in same position.
- If undo pressed within 5 seconds:
  - Transaction restored to original position.
- If timer expires:
  - Repository delete is committed (soft delete in Supabase).

### 7.4 Auto-post of Recurring Expenses
- On load, auto-post check is triggered once per session.
- If due occurrences are found, transactions are created (see Section 14).

### 7.5 Empty States
- If no transactions: EmptyStateWidget with CTA to add.
- If filters remove all results: No results state with clear filters/search.

---

## 8) Add/Edit Transaction

File: `lib/presentation/add_transaction/add_transaction.dart`

Fields:
- Amount (required)
- Type (income/expense)
- Description (required)
- Date (required, default today)
- Category (required)
- Payment method (required)
- Client (optional)
- Quick templates (optional, presets)

Form validation:
- Amount parsed via `IncoreNumberFormatter.parseAmount`.
- Must be > 0.

Save behavior:
- If editing, updateTransaction.
- Else, addTransaction.
- On success: show Snackbar and pop with `true`.
- On LimitReachedException: show info, remain on screen.

Date picker:
- Date range: from 2020 to now + 365 days.

Transaction type toggle:
- Switching type clears category and template.

Quick templates:
- Prefill description + amount; category is NOT auto-assigned.

---

## 9) Recurring Expenses

File: `lib/presentation/recurring_expenses/recurring_expenses.dart`

CRUD:
- Add/Edit dialog uses AddEditRecurringExpenseDialog.
- Delete uses confirm dialog.
- Toggle active/inactive uses repository with entitlement checks.

Add/Edit validation:
- Amount > 0
- Due day between 1 and 31

List view:
- Shows all recurring expenses with active/inactive styling.

---

## 10) Analytics Gate

File: `lib/presentation/analytics_dashboard/analytics_gate_screen.dart`

Purpose:
- Prevents free users from accessing Analytics (unless debug or unsupported platform).

Flow:
- If debug or non-mobile platform: allow access.
- If premium: allow access.
- If free: present paywall `analytics_gate` then re-check plan.
- If still free: navigate back or to dashboard.

---

## 11) Analytics Dashboard

File: `lib/presentation/analytics_dashboard/analytics_dashboard.dart`

Sections:
- Insight Card (if any)
- Safety Buffer + Pressure Point
- Tax Reserve row
- Recurring Expenses row
- Overview (range selector, Income vs Expenses chart, MoM card)
- Breakdown (income/expense top categories)
- Trends (Cash Balance, Profit Trends)

Range selector:
- 3 months, 6 months, 12 months
- Affects monthly charts and cash balance chart lookback days.

Detailed formulas and chart logic are documented in Sections 12 and 13.

---

## 12) Financial Calculations

### 12.1 Income vs Expenses (Monthly)
- For each month in range:
  - income = sum of income transactions in month
  - expenses = sum of expense transactions in month
- Month label: MMM + yy

Interpretation rules:
- Risk: income <= 0 and expenses > 0
- Risk: expenses > income
- Watch: expenses >= income * 0.8 AND income >= 100
- Healthy: otherwise

### 12.2 Profit Trends (Monthly)
- profit = income - expenses for each month

Interpretation rules:
- Risk: latest profit < 0
- Watch: last 3 points strictly decreasing with >= 15% drop
- Healthy: otherwise

### 12.3 Cash Balance Trend (Daily)
- days lookback = 90 (3m), 180 (6m), 365 (12m)
- chart baseline = starting_balance + net of all transactions before period
- for each day: runningBalance += net change (income - expense)

Interpretation rules:
- Risk: latest balance <= 0
- Watch: latest <= 25% of peak
- Watch: last 3 points strictly decreasing with >= 15% drop
- Healthy: otherwise

### 12.4 Category Breakdown
- Totals by category (income or expense)
- Top 3 categories + Others
- percentage = category_total / total * 100

Interpretation rules:
- Risk: top share >= 60%
- Watch: 40% <= top share < 60%
- Healthy: top share < 40%

### 12.5 Month-over-Month Comparison
- Compare current month vs previous month
- Change % = (current - previous) / previous * 100
- If previous == 0 and current > 0 => 100%
- If both zero => 0%

### 12.6 Tax Shield
File: `lib/domain/tax_shield/tax_shield_calculator.dart`

- recentMonthStart = first day of last full month
- priorMonthStart = first day of month before last
- if both months income > 0: monthlyInflow = avg of two
- else: monthlyInflow = last month only

- taxShieldPercent from settings (default 0.25)
- taxShieldReserved = monthlyInflow * taxShieldPercent
- availableAfterTax = max(0, latestBalance - taxShieldReserved)

### 12.7 Safety Buffer
File: `lib/domain/safety_buffer/safety_buffer_calculator.dart`

Inputs: TaxShieldSnapshot + monthlyFixedOutflow

- dailyFixedOutflow = monthlyFixedOutflow / 30
- dailyInflow = monthlyInflow / 30
- dailyNet = dailyInflow - dailyFixedOutflow

Buffer days:
- if dailyFixedOutflow <= 0 -> null
- else if available <= 0 -> 0
- else if dailyNet >= 0 -> maxBufferDays (180)
- else -> floor(available / abs(dailyNet)), capped at 180

Buffer weeks:
- bufferDays / 7 (1 decimal)

### 12.8 Pressure Point
File: `lib/presentation/analytics_dashboard/widgets/safety_buffer_section.dart`

Shown if:
- no active insight card
- bufferDays < 45
- total due in next 7 days > 0

Due totals:
- uses next due date for each recurring expense (dueDay clamped)
- sum of amounts due in 7-day and 14-day windows

---

## 13) Charts and Visual Rules

### 13.1 Income vs Expenses (Bar)
File: `lib/presentation/analytics_dashboard/widgets/income_expenses_chart_widget.dart`

- Two bars per month: income (teal), expense (rose)
- Y-axis tick interval: "nice" steps (50..100000)
- Max Y rounded up to next tick
- X-axis labels: first/last, plus mid for 6m, every 2 months for 12m
- Tooltip shows month + type + formatted value

### 13.2 Profit Trends (Line)
File: `lib/presentation/analytics_dashboard/widgets/profit_trends_chart_widget.dart`

- Line + dots, curved
- Fill gradient below line
- X-axis interval: 1 for <=3, 2 for <=6, 3 for >6
- Y-axis "nice" ticks

### 13.3 Cash Balance (Line)
File: `lib/presentation/analytics_dashboard/widgets/cash_balance_chart.dart`

- Dots only on days with transactions
- X-axis label density:
  - <=30: weekly
  - <=90: every 14 days
  - <=180: every 30 days
  - >180: every 60 days
- Tooltip shows MMM d and formatted balance

---

## 14) Recurring Auto-Posting

File: `lib/services/recurring_expenses_auto_poster.dart`

Purpose:
- Automatically create transactions for due recurring expenses.

Rules:
- Considers active recurring expenses.
- Calculates due occurrences up to today.
- Uses maxOccurrencesPerRun (default 6).
- Inserts transactions with:
  - category: other_expense
  - type: expense
  - payment_method: bank_transfer
  - recurring_expense_id + occurrence_date
- Uses unique constraint for idempotency (skips duplicates).
- Updates last_posted_occurrence_date per expense.

Guard:
- `RecurringAutoPosterGuard` ensures once per session run.

---

## 15) Entitlements, Plans, and Usage Limits

### 15.1 Plan Types
File: `lib/domain/entitlements/plan_type.dart`

- free
- premium

### 15.2 Entitlement Config
File: `lib/domain/entitlements/entitlement_config.dart`

Defaults:
- freeMaxSpendEntries: 20 per month
- freeMaxRecurringExpenses: 3 active
- freeMaxIncomeEvents: 3 per month
- freeCanAccessAnalytics: false
- freeCanViewHistoricalData: false
- freeCanExportData: false

### 15.3 SubscriptionService
File: `lib/services/subscription/subscription_service.dart`

- Uses Superwall on iOS/Android only.
- presentPaywall trigger IDs:
  - post_onboarding (once ever)
  - analytics_gate
  - limit_crossed_* metrics
- Cooldown:
  - 7 days for marketing triggers
  - none for access gates and limit triggers

### 15.4 Usage Counting
- Source-of-truth counts are computed by querying tables (not usage_metrics).
- `SupabaseWindowedUsageCounter` counts:
  - transactions in current calendar month
  - active recurring expenses
  - income events not yet implemented

### 15.5 usage_metrics (Telemetry)
- Incremented/decremented on add/delete.
- Not used for limit enforcement.

---

## 16) Settings Screen

File: `lib/presentation/settings/settings.dart`

Sections:
1) Account
   - name/email (read-only)
   - delete account (confirmation; not implemented)

2) Subscription
   - current plan
   - manage subscription (mobile only)
   - restore purchases

3) General
   - language (en/pt)
   - dark mode (stored locally)
   - currency selector
   - first day of week

4) Privacy and Security
   - biometric toggle
   - notifications toggle

5) Data
   - export data (premium only)
   - reset onboarding (debug only)
   - clear cache (disabled)
   - diagnostics

6) Support
   - contact support
   - privacy policy
   - terms of service

---

## 17) Localization + Formatting

- Language: en/pt stored in SharedPreferences under 'language'.
- Currency settings stored via UserSettingsService.
- Number formatting uses `IncoreNumberFormatter` (intl).` 

---

## 18) UI Design System (Current)

Files: `lib/theme/app_theme.dart`, `lib/theme/app_colors.dart`

- Font: Manrope (GoogleFonts).
- Primary color: AppColors.primary (slate/blue).
- Income color: teal palette.
- Expense color: rose palette.
- Frosted glass styling uses:
  - surfaceGlass80Light
  - borderGlass60Light
  - AppShadows.cardLight
- Radii:
  - radiusSmall 8, radiusMedium 12, radiusLarge 16, radiusCardXL 28
- Spacing constants in AppTheme.

---

## 19) Error Handling

- AppError + AppErrorClassifier used across major screens.
- Auth errors route to AuthGuardErrorScreen.
- Network errors use SnackBar or inline AppErrorWidget.
- Add/edit flows show user-friendly snackbars.

---

## 20) Feature Gaps / TODOs (as currently noted in code)

- income_events feature not implemented.
- Some analytics widgets in `analytics_dashboard/widgets` are not wired to current screen (legacy or unused).
- Export is gated and not implemented (dialog only).
- Delete account is not implemented.

---

End of PRD.
