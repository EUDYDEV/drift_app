CREATE TABLE IF NOT EXISTS voyages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE voyages
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS start_date DATE,
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE voyages
SET title = COALESCE(NULLIF(title, ''), 'Voyage DriFt')
WHERE title IS NULL OR btrim(title) = '';

INSERT INTO users (email, full_name, password_hash)
VALUES ('legacy-import@drift.local', 'Legacy Import', 'legacy-import')
ON CONFLICT (email) DO NOTHING;

UPDATE voyages
SET user_id = legacy.id
FROM (
  SELECT id
  FROM users
  WHERE email = 'legacy-import@drift.local'
  LIMIT 1
) AS legacy
WHERE voyages.user_id IS NULL;

ALTER TABLE voyages
  ALTER COLUMN title SET NOT NULL,
  ALTER COLUMN user_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'voyages_user_id_fkey'
  ) THEN
    ALTER TABLE voyages
      ADD CONSTRAINT voyages_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_voyages_user_id ON voyages(user_id);
