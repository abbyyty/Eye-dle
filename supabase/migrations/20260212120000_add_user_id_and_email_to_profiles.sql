-- Migration: Rebuild profiles table with user_id as 2nd column, email as 4th column
DO $$
BEGIN
  -- Rename old table
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    ALTER TABLE public.profiles RENAME TO profiles_old;
  END IF;

  -- Create new table
  CREATE TABLE public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id uuid NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
  );

  -- Copy data from old table if exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles_old') THEN
    INSERT INTO public.profiles (id, user_id, username, email, created_at)
      SELECT id, id AS user_id, username, '' AS email, created_at FROM public.profiles_old;
    DROP TABLE public.profiles_old;
  END IF;
END$$;

-- Update trigger function to insert all fields
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, user_id, username, email)
  VALUES (
    new.id,
    new.id,
    COALESCE(new.raw_user_meta_data ->> 'username', 'User'),
    COALESCE(new.email, '')
  );
  RETURN new;
END;
$$;
