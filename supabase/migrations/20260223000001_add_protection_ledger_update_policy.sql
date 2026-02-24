-- ============================================================================
-- Add missing UPDATE policy to protection_ledger
-- ============================================================================

DROP POLICY IF EXISTS "Users can update own ledger entries" ON public.protection_ledger;

CREATE POLICY "Users can update own ledger entries"
  ON public.protection_ledger FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
