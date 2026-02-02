# Monetization and Control Layer

This document describes the subscription monetization layer for the Incore Finance app.

## Overview

The monetization layer implements a freemium model with:
- **Free Plan**: Basic features with usage limits
- **Premium Plan**: Full access to all features with no limits

## Plan Definitions

### Free Plan
- Limited spend entries (20 transactions per calendar month)
- Limited recurring expenses (3 active at same time)
- Limited income events (3 per calendar month)
- No analytics access
- No historical data access
- No export functionality

### Premium Plan
- Unlimited spend entries
- Unlimited recurring expenses
- Unlimited income events
- Full analytics access
- Historical data access
- Export to PDF and CSV

## Window-Based Limits

Limits are enforced using **window-based counting**, not lifetime counts:

| Metric | Window | Limit | Description |
|--------|--------|-------|-------------|
| Transactions | Calendar month | 20 | Based on user-selected transaction date |
| Recurring expenses | Active count | 3 | Currently active items only |
| Income events | Calendar month | 3 | Based on user-selected date |

### Key Behaviors

1. **Monthly windows reset on the 1st** - A user who added 20 transactions in January can add 20 more starting February 1st.

2. **User-selected date matters** - If a user backdates a transaction to January while in February, it counts against January's limit, not February's.

3. **Active count for recurring** - Deactivating a recurring expense allows adding another; reactivating counts toward the limit again.

4. **Block before save** - The limit check happens BEFORE the database insert. If at limit, the transaction is NOT saved.

### Month Boundary Calculation

The `month_window.dart` helper handles timezone-aware month boundaries:

```dart
// For timestamptz columns (like transactions.date)
final (monthStart, nextMonthStart) = getCurrentMonthBoundaries(MonthWindowMode.timestamptz);
// Uses UTC boundaries for database queries

// For date-only columns
final (monthStart, nextMonthStart) = getCurrentMonthBoundaries(MonthWindowMode.dateOnly);
// Uses local timezone boundaries
```

## Enforcement vs Telemetry

### Enforcement Layer (WindowedUsageCounter)

Limits are enforced by counting directly from **source tables**:

```dart
// Count from transactions table with date filter
final count = await _usageCounter.transactionsThisMonth();

// Count from recurring_expenses table where is_active = true
final count = await _usageCounter.activeRecurringExpenses();
```

This ensures accurate real-time counts that cannot drift out of sync.

### Telemetry Layer (UsageMetricsRepository)

The `usage_metrics` table is now **telemetry only**:
- Used for analytics and reporting
- Incremented after successful inserts
- NOT used for limit enforcement
- Failure to increment does not block operations

```dart
// After successful insert
try {
  await UsageMetricsRepository().increment(UsageMetricsRepository.spendEntriesCount);
} catch (e) {
  AppLogger.w('Failed to increment telemetry', error: e);
  // Continue - telemetry failure is non-blocking
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ AddTransaction  │  │ RecurringExp    │  │ AnalyticsGate   │ │
│  │ catches Limit   │  │ catches Limit   │  │ Screen          │ │
│  │ ReachedException│  │ ReachedException│  │                 │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
└───────────┼─────────────────────┼─────────────────────┼─────────┘
            │                     │                     │
            ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Services Layer                             │
│  ┌──────────────────────────────┐  ┌───────────────────────────┐│
│  │   TransactionsRepository     │  │   RecurringExpensesRepo   ││
│  │   - Check limit BEFORE insert│  │   - Check limit BEFORE    ││
│  │   - Throw LimitReached       │  │   - Throw LimitReached    ││
│  └──────────────┬───────────────┘  └─────────────┬─────────────┘│
│                 │                                │               │
│  ┌──────────────▼────────────────────────────────▼──────────────┐│
│  │                  SubscriptionService                         ││
│  │  - getCurrentPlan()                                          ││
│  │  - presentPaywall(triggerId) (no cooldown for limits)        ││
│  │  - restorePurchases()                                        ││
│  │  - post_onboarding: once ever                                ││
│  └──────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Domain Layer                              │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐│
│  │  EntitlementService  │  │    WindowedUsageCounter          ││
│  │  (Pure Logic)        │  │    (Interface)                   ││
│  │                      │  │                                  ││
│  │  - canAccessAnalytics│  │  - transactionsThisMonth()       ││
│  │  - canAddMore*()     │  │  - activeRecurringExpenses()     ││
│  │  - getLimitForMetric │  │  - incomeEventsThisMonth()       ││
│  └──────────────────────┘  └──────────────────────────────────┘│
│                                                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐│
│  │  EntitlementConfig   │  │  LimitReachedException           ││
│  │  (20, 3, 3 limits)   │  │  (Block without save)            ││
│  └──────────────────────┘  └──────────────────────────────────┘│
│                                                                 │
│  ┌──────────────────────┐                                       │
│  │  month_window.dart   │                                       │
│  │  (Month boundaries)  │                                       │
│  └──────────────────────┘                                       │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │          SupabaseWindowedUsageCounter (ENFORCEMENT)         ││
│  │  - Counts from source tables with date filters              ││
│  │  - Uses Supabase exact count option                         ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │          UsageMetricsRepository (TELEMETRY ONLY)            ││
│  │  - Increment after successful inserts                       ││
│  │  - Failure does not block operations                        ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase                                   │
│  ┌──────────────────────────────┐  ┌───────────────────────────┐│
│  │   transactions table         │  │  recurring_expenses table ││
│  │   (ENFORCEMENT: count here)  │  │  (ENFORCEMENT: count here)││
│  │   - date (timestamptz)       │  │  - is_active (bool)       ││
│  └──────────────────────────────┘  └───────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              usage_metrics table (TELEMETRY ONLY)           ││
│  │  - NOT used for limit enforcement                           ││
│  │  - Used for analytics and reporting                         ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### Pure Domain Logic

The `UsageLimitMonitor` is **pure domain logic**:
- It only marks and logs when limits are crossed
- It does NOT trigger paywalls
- Paywall orchestration is handled by `SubscriptionService.handleLimitCrossed()`

This separation ensures:
- Testable business logic
- Clear responsibility boundaries
- No side effects in the domain layer

### Analytics Gating

Analytics access is gated at the **screen entry point**, not in the bottom bar:
- `AnalyticsGateScreen` checks entitlement before showing `AnalyticsDashboard`
- Avoids async issues in navigation
- Clean separation of concerns

### Paywall Cooldown Rules

Paywalls have different cooldown behavior based on trigger type:

| Trigger Type | Cooldown | Behavior |
|--------------|----------|----------|
| **Access gates** (`analytics_gate`) | None | Always shows paywall |
| **Limit gates** (`limit_crossed_*`) | None | Always shows paywall |
| **post_onboarding** | Once ever | Shows only once per user lifetime |
| **Marketing triggers** | 7 days | Prevents paywall fatigue |

#### Access Gates (No Cooldown)
When a free user taps Analytics, they see the paywall **every time**. This is intentional - the feature is gated, not rationed.

#### Limit Gates (No Cooldown)
When a free user is at their limit and tries to add another item, they see the paywall **every time**. This allows immediate retry after upgrading.

#### post_onboarding (Once Ever)
The post-onboarding paywall shows **only once** per user lifetime, not with a 7-day cooldown. This is tracked via a boolean flag in SharedPreferences, set AFTER successful presentation.

```dart
// Set AFTER successful presentation to handle edge cases
if (isPostOnboarding) {
  await prefs.setBool(_postOnboardingShownKey, true);
}
```

#### Marketing Triggers (7-Day Cooldown)
Other promotional paywalls (e.g., settings_upgrade) have a 7-day cooldown to prevent fatigue.

Cooldowns are persisted in **SharedPreferences** to survive app restarts.

## Paywall Trigger Points

| Trigger ID | Location | Description |
|------------|----------|-------------|
| `post_onboarding` | OnboardingFlow | After completing onboarding |
| `analytics_gate` | AnalyticsGateScreen | When accessing Analytics without premium |
| `settings_upgrade` | SubscriptionScreen | From upgrade button in settings |
| `limit_crossed_spend_entries_count` | TransactionsRepository | When spend entries limit crossed |
| `limit_crossed_recurring_expenses_count` | RecurringExpensesRepository | When recurring expenses limit crossed |
| `limit_crossed_income_events_count` | (Future) | When income events limit crossed |

## Database Schema

### usage_metrics Table

```sql
CREATE TABLE IF NOT EXISTS usage_metrics (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  metric_type text NOT NULL,
  value int NOT NULL DEFAULT 0,
  last_crossed_limit_at timestamptz NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, metric_type)
);

-- Enable RLS
ALTER TABLE usage_metrics ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own rows
CREATE POLICY "Users can view own usage_metrics"
  ON usage_metrics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own usage_metrics"
  ON usage_metrics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own usage_metrics"
  ON usage_metrics FOR UPDATE
  USING (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX idx_usage_metrics_user_metric
  ON usage_metrics(user_id, metric_type);
```

### Metric Types

| Metric Type | Description |
|-------------|-------------|
| `spend_entries_count` | Number of transactions |
| `recurring_expenses_count` | Number of recurring expenses |
| `income_events_count` | Number of income events (future) |

## Usage Tracking Flow

### Adding a Transaction (Free User)

```
User taps Save
      │
      ▼
┌─────────────────────────────────┐
│ 1. Check plan type              │
│    plan = getCurrentPlan()      │
└─────────────────────────────────┘
      │
      ▼ (if free)
┌─────────────────────────────────┐
│ 2. Count current month usage    │
│    count = transactionsThisMonth│
└─────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────┐
│ 3. Is count >= limit?           │
└─────────────────────────────────┘
      │
      ├─── Yes ───▶ Show paywall
      │            Throw LimitReachedException
      │            Transaction NOT saved
      │
      ▼ No
┌─────────────────────────────────┐
│ 4. Insert transaction           │
└─────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────┐
│ 5. Increment telemetry (async)  │
│    Non-blocking on failure      │
└─────────────────────────────────┘
      │
      ▼
   Success
```

### Key Points

1. **Check BEFORE insert** - The limit check happens before saving. If at limit, nothing is saved.
2. **Throw exception** - `LimitReachedException` allows UI to handle gracefully without return type changes.
3. **Paywall on every attempt** - No cooldown for limit gates. User can retry immediately after upgrading.
4. **Telemetry is non-blocking** - If `usage_metrics` increment fails, the transaction is still saved.

## File Structure

```
lib/
├── domain/
│   ├── entitlements/
│   │   ├── plan_type.dart
│   │   ├── entitlement_config.dart          # Limit values (20, 3, 3)
│   │   └── entitlement_service.dart
│   └── usage/
│       ├── usage_limit_monitor.dart         # Legacy (telemetry only)
│       ├── windowed_usage_counter.dart      # Interface for counting
│       ├── month_window.dart                # Month boundary helpers
│       └── limit_reached_exception.dart     # Exception for limit blocks
├── data/
│   └── usage/
│       ├── usage_metrics_repository.dart    # Telemetry only
│       └── supabase_windowed_usage_counter.dart  # Enforcement counting
├── services/
│   ├── transactions_repository.dart         # Limit check before insert
│   ├── recurring_expenses_repository.dart   # Limit check before insert
│   └── subscription/
│       └── subscription_service.dart        # Paywall orchestration
└── presentation/
    ├── add_transaction/
    │   └── add_transaction.dart             # Catches LimitReachedException
    ├── recurring_expenses/
    │   ├── recurring_expenses.dart          # Catches on reactivate
    │   └── widgets/
    │       └── add_edit_recurring_expense_dialog.dart  # Catches on add
    ├── analytics_dashboard/
    │   └── analytics_gate_screen.dart
    └── settings/
        └── subscription_screen.dart

test/
└── domain/
    ├── entitlements/
    │   └── entitlement_service_test.dart
    └── usage/
        └── month_window_test.dart           # Month boundary unit tests
```

## Testing

### Unit Tests

`EntitlementService` has comprehensive unit tests covering:
- All methods return `true` for premium plan
- All methods respect limits for free plan
- Boundary conditions (exactly at limit, one below, one above)
- Custom config injection for edge cases

Run tests:
```bash
flutter test test/domain/entitlements/
```

## TODOs

### Superwall Integration
The `SubscriptionService` has TODO comments for Superwall SDK integration:
- `getCurrentPlan()` - Query Superwall subscription status
- `presentPaywall()` - Present via Superwall
- `restorePurchases()` - Restore via Superwall

### Income Events
When income events feature is implemented:
- Implement `incomeEventsThisMonth()` in `SupabaseWindowedUsageCounter`
- Add limit check in income events repository
- Wire telemetry `increment(incomeEventsCount)` on create

### URL Launcher
Add `url_launcher` dependency for subscription management links:
- iOS: `itms-apps://apps.apple.com/account/subscriptions`
- Android: `https://play.google.com/store/account/subscriptions`

---

## Changelog

### 2026-01-30: Window-Based Limits

**Breaking changes:**
- Limits are now window-based, not lifetime
- Transactions: 20/month (was 50 lifetime)
- Recurring expenses: 3 active (was 5 lifetime)
- Income events: 3/month (unchanged)

**New behavior:**
- Enforcement counts from source tables, not usage_metrics
- usage_metrics is now telemetry only
- Limit check happens BEFORE insert (block without save)
- LimitReachedException thrown instead of return type changes
- No cooldown for access gates and limit gates
- post_onboarding paywall shows once ever (not 7-day cooldown)

**New files:**
- `lib/domain/usage/windowed_usage_counter.dart`
- `lib/domain/usage/month_window.dart`
- `lib/domain/usage/limit_reached_exception.dart`
- `lib/data/usage/supabase_windowed_usage_counter.dart`
- `test/domain/usage/month_window_test.dart`
