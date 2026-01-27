-- Migration: Create user_financial_baseline table
-- Purpose: Store starting balance for each user (financial baseline)
-- Date: 2026-01-26
-- Status: Data layer foundation for cash balance calculations

-- ============================================================================
-- Create user_financial_baseline table
-- ============================================================================

-- Create table
CREATE TABLE IF NOT EXISTS public.user_financial_baseline (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  starting_balance numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_financial_baseline_user_id
  ON public.user_financial_baseline(user_id);

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_user_financial_baseline_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_financial_baseline_updated_at
  ON public.user_financial_baseline;

CREATE TRIGGER trg_user_financial_baseline_updated_at
BEFORE UPDATE ON public.user_financial_baseline
FOR EACH ROW
EXECUTE FUNCTION update_user_financial_baseline_updated_at();

-- RLS
ALTER TABLE public.user_financial_baseline ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "user_financial_baseline_select_own"
  ON public.user_financial_baseline;

CREATE POLICY "user_financial_baseline_select_own"
  ON public.user_financial_baseline
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_financial_baseline_insert_own"
  ON public.user_financial_baseline;

CREATE POLICY "user_financial_baseline_insert_own"
  ON public.user_financial_baseline
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_financial_baseline_update_own"
  ON public.user_financial_baseline;

CREATE POLICY "user_financial_baseline_update_own"
  ON public.user_financial_baseline
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_financial_baseline_delete_own"
  ON public.user_financial_baseline;

CREATE POLICY "user_financial_baseline_delete_own"
  ON public.user_financial_baseline
  FOR DELETE
  USING (auth.uid() = user_id);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.user_financial_baseline
  TO authenticated;