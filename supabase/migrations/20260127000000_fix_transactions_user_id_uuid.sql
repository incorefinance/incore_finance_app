-- Migration: Fix transactions.user_id type from bigint to uuid
--
-- Problem: The transactions table has user_id typed as bigint, but
-- Supabase auth uses UUID for user identifiers. This causes
-- "invalid input syntax for type bigint" errors when querying.
--
-- Solution: Change user_id column to uuid type and add foreign key
-- to auth.users for RLS compatibility.
--
-- IMPORTANT: Run this migration ONLY if user_id is currently bigint.
-- Check first with: SELECT data_type FROM information_schema.columns
-- WHERE table_name = 'transactions' AND column_name = 'user_id';

-- Migration: Fix public.transactions.user_id to uuid for Supabase auth compatibility

BEGIN;

DO $$
DECLARE
  col_type text;
  row_count bigint;
BEGIN
  SELECT data_type INTO col_type
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'transactions'
    AND column_name = 'user_id';

  IF col_type IS NULL THEN
    RAISE EXCEPTION 'Column public.transactions.user_id does not exist';
  END IF;

  IF col_type = 'uuid' THEN
    RAISE NOTICE 'transactions.user_id already uuid, skipping';
    RETURN;
  END IF;

  IF col_type <> 'bigint' THEN
    RAISE EXCEPTION 'Unexpected type for transactions.user_id: %', col_type;
  END IF;

  SELECT COUNT(*) INTO row_count FROM public.transactions;
  IF row_count > 0 THEN
    RAISE EXCEPTION 'transactions has % rows. Cannot auto migrate bigint user_id to uuid without mapping', row_count;
  END IF;

  EXECUTE 'ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_user_id_fkey';

  EXECUTE 'DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions';
  EXECUTE 'DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.transactions';
  EXECUTE 'DROP POLICY IF EXISTS "Users can update their own transactions" ON public.transactions';
  EXECUTE 'DROP POLICY IF EXISTS "Users can delete their own transactions" ON public.transactions';

  EXECUTE 'ALTER TABLE public.transactions ADD COLUMN user_id_uuid uuid';
  EXECUTE 'ALTER TABLE public.transactions DROP COLUMN user_id';
  EXECUTE 'ALTER TABLE public.transactions RENAME COLUMN user_id_uuid TO user_id';
  EXECUTE 'ALTER TABLE public.transactions ALTER COLUMN user_id SET NOT NULL';

  EXECUTE 'ALTER TABLE public.transactions ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE';
  EXECUTE 'CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id)';
  EXECUTE 'ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY';

  EXECUTE 'CREATE POLICY "Users can view their own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id)';
  EXECUTE 'CREATE POLICY "Users can insert their own transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id)';
  EXECUTE 'CREATE POLICY "Users can update their own transactions" ON public.transactions FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id)';
  EXECUTE 'CREATE POLICY "Users can delete their own transactions" ON public.transactions FOR DELETE USING (auth.uid() = user_id)';

  EXECUTE 'COMMENT ON COLUMN public.transactions.user_id IS ''UUID reference to auth.users(id). Used for RLS policies.''';

  RAISE NOTICE 'transactions.user_id migrated from bigint to uuid';
END $$;

COMMIT;
