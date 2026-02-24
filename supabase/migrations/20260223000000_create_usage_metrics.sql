-- ============================================================================
-- Table: usage_metrics
-- Purpose: Track per-user usage counts for monetization and free plan limits
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.usage_metrics (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  metric_type TEXT NOT NULL,
  value INTEGER NOT NULL DEFAULT 0,
  last_crossed_limit_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, metric_type)
);

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE public.usage_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own metrics"
  ON public.usage_metrics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own metrics"
  ON public.usage_metrics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own metrics"
  ON public.usage_metrics FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_usage_metrics_user_id
  ON public.usage_metrics(user_id);

-- ============================================================================
-- Grants
-- ============================================================================

GRANT SELECT, INSERT, UPDATE
  ON public.usage_metrics
  TO authenticated;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE public.usage_metrics IS
  'Per-user usage counters for monetization. Tracks spend entries, recurring expenses, and income events.';
