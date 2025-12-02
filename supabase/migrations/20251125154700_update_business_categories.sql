-- Location: supabase/migrations/20251125154700_update_business_categories.sql
-- Schema Analysis: Existing transactions table with category TEXT column
-- Integration Type: Modificative - Adding constraint to existing table
-- Dependencies: public.transactions

-- Create enum type for business category identifiers
CREATE TYPE public.business_category AS ENUM (
    'rev_sales',
    'mkt_ads',
    'mkt_software',
    'mkt_subs',
    'ops_equipment',
    'ops_supplies',
    'pro_accounting',
    'pro_contractors',
    'travel_general',
    'travel_meals',
    'ops_rent',
    'ops_insurance',
    'ops_taxes',
    'ops_fees',
    'people_salary',
    'people_training',
    'other_expense',
    'other_refunds'
);

-- Add constraint to transactions.category to only accept valid business category identifiers
ALTER TABLE public.transactions
DROP CONSTRAINT IF EXISTS check_business_category;

ALTER TABLE public.transactions
ADD CONSTRAINT check_business_category
CHECK (
    category IN (
        'rev_sales',
        'mkt_ads',
        'mkt_software',
        'mkt_subs',
        'ops_equipment',
        'ops_supplies',
        'pro_accounting',
        'pro_contractors',
        'travel_general',
        'travel_meals',
        'ops_rent',
        'ops_insurance',
        'ops_taxes',
        'ops_fees',
        'people_salary',
        'people_training',
        'other_expense',
        'other_refunds'
    )
);

-- Update existing transactions to map old categories to new business identifiers
-- This safely migrates existing data to the new category system
DO $$
BEGIN
    -- Update income categories
    UPDATE public.transactions SET category = 'rev_sales' WHERE category IN ('Salary', 'Freelance', 'Business', 'Other Income');
    UPDATE public.transactions SET category = 'other_refunds' WHERE category IN ('Investment', 'Gift');
    
    -- Update expense categories
    UPDATE public.transactions SET category = 'travel_meals' WHERE category = 'Food & Dining';
    UPDATE public.transactions SET category = 'travel_general' WHERE category IN ('Transportation', 'Travel');
    UPDATE public.transactions SET category = 'mkt_ads' WHERE category IN ('Shopping', 'Entertainment');
    UPDATE public.transactions SET category = 'ops_rent' WHERE category = 'Bills & Utilities';
    UPDATE public.transactions SET category = 'pro_accounting' WHERE category IN ('Healthcare', 'Education');
    UPDATE public.transactions SET category = 'other_expense' WHERE category = 'Other Expense';
    
    -- Any remaining unmapped categories default to other_expense
    UPDATE public.transactions SET category = 'other_expense' WHERE category NOT IN (
        'rev_sales', 'mkt_ads', 'mkt_software', 'mkt_subs', 'ops_equipment', 'ops_supplies',
        'pro_accounting', 'pro_contractors', 'travel_general', 'travel_meals', 'ops_rent',
        'ops_insurance', 'ops_taxes', 'ops_fees', 'people_salary', 'people_training',
        'other_expense', 'other_refunds'
    );
END $$;

-- Create index for category queries (improves filter and analytics performance)
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category);

-- Add comment explaining the category system
COMMENT ON COLUMN public.transactions.category IS 'Business category identifier (e.g., rev_sales, mkt_ads). Use category mapping in application to display user-friendly labels.';