-- Migration: Create user_onboarding_status table
-- Purpose: Track onboarding completion per user account (server-side)
-- Date: 2026-01-26
-- Status: Ensures onboarding state is consistent across devices

-- ============================================================================
-- Create user_onboarding_status table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_onboarding_status (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  onboarding_completed boolean NOT NULL DEFAULT false,
  completed_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_onboarding_status_user_id
  ON public.user_onboarding_status(user_id);

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_user_onboarding_status_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_onboarding_status_updated_at
  ON public.user_onboarding_status;

CREATE TRIGGER trg_user_onboarding_status_updated_at
BEFORE UPDATE ON public.user_onboarding_status
FOR EACH ROW
EXECUTE FUNCTION update_user_onboarding_status_updated_at();

-- RLS
ALTER TABLE public.user_onboarding_status ENABLE ROW LEVEL SECURITY;

-- Policies (drop first since Postgres doesn't support IF NOT EXISTS for policies)
DROP POLICY IF EXISTS "user_onboarding_status_select_own"
  ON public.user_onboarding_status;

CREATE POLICY "user_onboarding_status_select_own"
  ON public.user_onboarding_status
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_onboarding_status_insert_own"
  ON public.user_onboarding_status;

CREATE POLICY "user_onboarding_status_insert_own"
  ON public.user_onboarding_status
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_onboarding_status_update_own"
  ON public.user_onboarding_status;

CREATE POLICY "user_onboarding_status_update_own"
  ON public.user_onboarding_status
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_onboarding_status_delete_own"
  ON public.user_onboarding_status;

CREATE POLICY "user_onboarding_status_delete_own"
  ON public.user_onboarding_status
  FOR DELETE
  USING (auth.uid() = user_id);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.user_onboarding_status
  TO authenticated;
