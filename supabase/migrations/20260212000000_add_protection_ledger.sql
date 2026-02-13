-- ============================================================================
-- Protection Ledger: tracks tax and safety allocations
-- Supports: Safe to Spend = Balance - Tax Reserve - Safety Buffer
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.protection_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Ownership
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Transaction linkage (must match transactions.id = BIGINT)
  source_transaction_id BIGINT REFERENCES public.transactions(id) ON DELETE CASCADE,
  trigger_transaction_id BIGINT REFERENCES public.transactions(id) ON DELETE SET NULL,

  -- Allocation details
  allocation_type TEXT NOT NULL CHECK (allocation_type IN ('tax', 'safety')),
  direction TEXT NOT NULL CHECK (direction IN ('credit', 'debit')),

  -- Percentage stored as decimal 0-1
  percentage_at_time NUMERIC CHECK (percentage_at_time >= 0 AND percentage_at_time <= 1),

  -- Amount with high precision
  amount NUMERIC NOT NULL CHECK (amount > 0),

  -- Time tracking
  effective_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Generated month key (UTC-based, immutable expression)
  month_key TEXT GENERATED ALWAYS AS (
    (EXTRACT(YEAR FROM (effective_at AT TIME ZONE 'UTC'))::int)::text
    || '-' ||
    LPAD((EXTRACT(MONTH FROM (effective_at AT TIME ZONE 'UTC'))::int)::text, 2, '0')
  ) STORED,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_protection_ledger_user_id
  ON public.protection_ledger(user_id);

CREATE INDEX IF NOT EXISTS idx_protection_ledger_source_tx
  ON public.protection_ledger(source_transaction_id);

CREATE INDEX IF NOT EXISTS idx_protection_ledger_trigger_tx
  ON public.protection_ledger(trigger_transaction_id);

CREATE INDEX IF NOT EXISTS idx_protection_ledger_month_key
  ON public.protection_ledger(month_key);

CREATE INDEX IF NOT EXISTS idx_protection_ledger_effective_at
  ON public.protection_ledger(effective_at);

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE public.protection_ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own ledger entries" ON public.protection_ledger;
CREATE POLICY "Users can view own ledger entries"
  ON public.protection_ledger FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own ledger entries" ON public.protection_ledger;
CREATE POLICY "Users can insert own ledger entries"
  ON public.protection_ledger FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own ledger entries" ON public.protection_ledger;
CREATE POLICY "Users can delete own ledger entries"
  ON public.protection_ledger FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- Trigger: inherit effective_at from source transaction for credits
-- ============================================================================

DROP TRIGGER IF EXISTS trg_protection_ledger_set_effective_at ON public.protection_ledger;
DROP FUNCTION IF EXISTS public.fn_protection_ledger_set_effective_at();

CREATE OR REPLACE FUNCTION public.fn_protection_ledger_set_effective_at()
RETURNS TRIGGER AS $$
BEGIN
  -- For income credits, inherit transaction.date
  IF NEW.direction = 'credit' AND NEW.source_transaction_id IS NOT NULL THEN
    SELECT (date::timestamp AT TIME ZONE 'UTC')
    INTO NEW.effective_at
    FROM public.transactions
    WHERE id = NEW.source_transaction_id;

    IF NEW.effective_at IS NULL THEN
      NEW.effective_at := now();
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protection_ledger_set_effective_at
  BEFORE INSERT ON public.protection_ledger
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_protection_ledger_set_effective_at();

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE public.protection_ledger IS
  'Tracks tax and safety buffer allocations. Credits from income, debits from overspending.';

COMMENT ON COLUMN public.protection_ledger.source_transaction_id IS
  'Income transaction (BIGINT id) that generated this credit. NULL for debits.';

COMMENT ON COLUMN public.protection_ledger.trigger_transaction_id IS
  'Expense transaction (BIGINT id) that triggered this debit. NULL for credits.';

COMMENT ON COLUMN public.protection_ledger.allocation_type IS
  'Type of protection: tax (never auto-decreased) or safety (can be drawn down).';

COMMENT ON COLUMN public.protection_ledger.direction IS
  'credit = allocation from income, debit = drawdown from ovesrspending.';
