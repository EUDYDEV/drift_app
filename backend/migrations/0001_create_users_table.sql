CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS full_name TEXT;

UPDATE users
SET full_name = split_part(email, '@', 1)
WHERE full_name IS NULL OR btrim(full_name) = '';

ALTER TABLE users
  ALTER COLUMN full_name SET NOT NULL;
