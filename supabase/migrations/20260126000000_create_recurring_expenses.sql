-- Location: supabase/migrations/20260126000000_create_recurring_expenses.sql
-- Schema Analysis: New table for recurring expenses (MVP: monthly frequency only)
-- Integration Type: Additive - Creating new table
-- Dependencies: auth.users (for user_id foreign key)

-- ============================================================================
-- Table: recurring_expenses
-- Purpose: Store recurring expense definitions for short-term pressure logic
-- Note: Frequency is implicitly monthly for MVP. Do not add frequency field yet.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.recurring_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    due_day INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_amount_positive CHECK (amount > 0),
    CONSTRAINT check_due_day_range CHECK (due_day >= 1 AND due_day <= 31)
);

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

-- Enable RLS on the table
ALTER TABLE public.recurring_expenses ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only SELECT their own recurring expenses
CREATE POLICY "Users can view their own recurring expenses"
    ON public.recurring_expenses
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can only INSERT with their own user_id
CREATE POLICY "Users can insert their own recurring expenses"
    ON public.recurring_expenses
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only UPDATE their own recurring expenses
CREATE POLICY "Users can update their own recurring expenses"
    ON public.recurring_expenses
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only DELETE their own recurring expenses
CREATE POLICY "Users can delete their own recurring expenses"
    ON public.recurring_expenses
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- Indexes
-- ============================================================================

-- Index for user queries (most common access pattern)
CREATE INDEX IF NOT EXISTS idx_recurring_expenses_user_id
    ON public.recurring_expenses(user_id);

-- Index for active expenses filtering
CREATE INDEX IF NOT EXISTS idx_recurring_expenses_user_active
    ON public.recurring_expenses(user_id, is_active)
    WHERE is_active = true;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE public.recurring_expenses IS
    'Recurring expense definitions. MVP uses monthly frequency only (implicit). Due day uses clamp-to-last-day-of-month rule when calculating next due date.';

COMMENT ON COLUMN public.recurring_expenses.due_day IS
    'Day of month when expense is due (1-31). For months with fewer days, clamp to last day of month (e.g., due_day=31 in February = Feb 28/29).';

COMMENT ON COLUMN public.recurring_expenses.is_active IS
    'Soft-delete flag. Set to false to deactivate without removing history.';
