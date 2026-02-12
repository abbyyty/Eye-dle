-- Migration: Add ON DELETE CASCADE to consent_records.user_id foreign key

-- 1. Drop existing foreign key constraint if exists
DO $$
DECLARE
  constraint_name text;
BEGIN
  SELECT tc.constraint_name INTO constraint_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
  WHERE tc.table_name = 'consent_records'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'user_id';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.consent_records DROP CONSTRAINT %I', constraint_name);
  END IF;
END$$;

-- 2. Add new foreign key with ON DELETE CASCADE
ALTER TABLE public.consent_records
  ADD CONSTRAINT consent_records_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
