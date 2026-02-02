-- Add income fields to user_onboarding_status
ALTER TABLE public.user_onboarding_status
  ADD COLUMN IF NOT EXISTS income_type text NULL,
  ADD COLUMN IF NOT EXISTS monthly_income_estimate numeric NULL;

-- Idempotent constraint: drop if exists, then add
ALTER TABLE public.user_onboarding_status
  DROP CONSTRAINT IF EXISTS user_onboarding_status_income_type_check;

ALTER TABLE public.user_onboarding_status
  ADD CONSTRAINT user_onboarding_status_income_type_check
  CHECK (income_type IS NULL OR income_type IN ('fixed', 'variable', 'mixed'));

COMMENT ON COLUMN public.user_onboarding_status.income_type IS 'User income pattern: fixed, variable, or mixed';
COMMENT ON COLUMN public.user_onboarding_status.monthly_income_estimate IS 'Optional monthly income estimate in user currency';
