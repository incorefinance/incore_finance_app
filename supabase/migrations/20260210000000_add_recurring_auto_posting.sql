-- Location: supabase/migrations/20260210000000_add_recurring_auto_posting.sql
-- Schema Analysis: Add support for recurring expense auto-posting
-- Integration Type: Additive - Adding columns and indexes
-- Dependencies: transactions, recurring_expenses tables

-- ============================================================================
-- 1. Add columns to transactions table
-- ============================================================================

-- Link transactions to their source recurring expense
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS recurring_expense_id UUID
    REFERENCES public.recurring_expenses(id) ON DELETE SET NULL;

-- Store the occurrence date (the due date this transaction represents)
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS occurrence_date DATE;

-- ============================================================================
-- 2. Add tracking column to recurring_expenses table
-- ============================================================================

-- Track last posted occurrence to speed up future runs
ALTER TABLE public.recurring_expenses
ADD COLUMN IF NOT EXISTS last_posted_occurrence_date DATE;

COMMENT ON COLUMN public.recurring_expenses.last_posted_occurrence_date IS
    'Date of the last auto-posted occurrence. Used to determine next occurrences to process.';

-- ============================================================================
-- 3. Create indexes
-- ============================================================================

-- Partial unique index for idempotency (only applies when recurring_expense_id is not null)
-- This prevents duplicate transactions for the same recurring expense occurrence
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_recurring_dedupe
ON public.transactions(user_id, recurring_expense_id, occurrence_date)
WHERE recurring_expense_id IS NOT NULL;

-- Index to find transactions linked to a recurring expense
CREATE INDEX IF NOT EXISTS idx_transactions_recurring_expense_id
ON public.transactions(recurring_expense_id)
WHERE recurring_expense_id IS NOT NULL;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON COLUMN public.transactions.recurring_expense_id IS
    'Reference to the recurring expense that generated this transaction. NULL for manually created transactions.';

COMMENT ON COLUMN public.transactions.occurrence_date IS
    'The due date this recurring transaction represents (e.g., 2026-02-15). Used with recurring_expense_id for deduplication.';
