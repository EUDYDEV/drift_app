CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL DEFAULT '',
  rating DOUBLE PRECISION NOT NULL DEFAULT 0,
  review_count INTEGER NOT NULL DEFAULT 0,
  vehicle_type TEXT NOT NULL DEFAULT 'economy',
  license_plate TEXT NOT NULL DEFAULT '',
  vehicle_color TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'offline',
  current_location JSONB NOT NULL DEFAULT '{"latitude":0,"longitude":0,"address":"Position inconnue","city":"Abidjan","country":"Côte d''Ivoire"}'::jsonb,
  eta INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS vehicle TEXT,
  ADD COLUMN IF NOT EXISTS license TEXT,
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS review_count INTEGER,
  ADD COLUMN IF NOT EXISTS vehicle_type TEXT,
  ADD COLUMN IF NOT EXISTS license_plate TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_color TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT,
  ADD COLUMN IF NOT EXISTS current_location JSONB,
  ADD COLUMN IF NOT EXISTS eta INTEGER,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE drivers
SET
  phone_number = COALESCE(phone_number, ''),
  rating = COALESCE(rating, 0),
  review_count = COALESCE(review_count, 0),
  vehicle_type = COALESCE(NULLIF(vehicle_type, ''), NULLIF(vehicle, ''), 'economy'),
  license_plate = COALESCE(NULLIF(license_plate, ''), NULLIF(license, ''), ''),
  vehicle_color = COALESCE(NULLIF(vehicle_color, ''), 'Noir'),
  status = COALESCE(NULLIF(status, ''), 'offline'),
  current_location = COALESCE(
    current_location,
    '{"latitude":0,"longitude":0,"address":"Position inconnue","city":"Abidjan","country":"Côte d''Ivoire"}'::jsonb
  ),
  eta = COALESCE(eta, 0);

ALTER TABLE drivers
  ALTER COLUMN phone_number SET DEFAULT '',
  ALTER COLUMN phone_number SET NOT NULL,
  ALTER COLUMN rating SET DEFAULT 0,
  ALTER COLUMN rating SET NOT NULL,
  ALTER COLUMN review_count SET DEFAULT 0,
  ALTER COLUMN review_count SET NOT NULL,
  ALTER COLUMN vehicle_type SET DEFAULT 'economy',
  ALTER COLUMN vehicle_type SET NOT NULL,
  ALTER COLUMN license_plate SET DEFAULT '',
  ALTER COLUMN license_plate SET NOT NULL,
  ALTER COLUMN vehicle_color SET DEFAULT '',
  ALTER COLUMN vehicle_color SET NOT NULL,
  ALTER COLUMN status SET DEFAULT 'offline',
  ALTER COLUMN status SET NOT NULL,
  ALTER COLUMN current_location SET DEFAULT '{"latitude":0,"longitude":0,"address":"Position inconnue","city":"Abidjan","country":"Côte d''Ivoire"}'::jsonb,
  ALTER COLUMN current_location SET NOT NULL,
  ALTER COLUMN eta SET DEFAULT 0,
  ALTER COLUMN eta SET NOT NULL;

CREATE TABLE IF NOT EXISTS rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  driver_id UUID,
  origin TEXT NOT NULL,
  destination TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'requested',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE rides
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS driver_id UUID,
  ADD COLUMN IF NOT EXISTS origin TEXT,
  ADD COLUMN IF NOT EXISTS destination TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

INSERT INTO users (email, full_name, password_hash)
VALUES ('legacy-import@drift.local', 'Legacy Import', 'legacy-import')
ON CONFLICT (email) DO NOTHING;

UPDATE rides
SET user_id = legacy.id
FROM (
  SELECT id
  FROM users
  WHERE email = 'legacy-import@drift.local'
  LIMIT 1
) AS legacy
WHERE rides.user_id IS NULL;

UPDATE rides
SET
  origin = COALESCE(NULLIF(origin, ''), 'Origine inconnue'),
  destination = COALESCE(NULLIF(destination, ''), 'Destination inconnue'),
  status = COALESCE(NULLIF(status, ''), 'requested');

ALTER TABLE rides
  ALTER COLUMN user_id SET NOT NULL,
  ALTER COLUMN origin SET NOT NULL,
  ALTER COLUMN destination SET NOT NULL,
  ALTER COLUMN status SET DEFAULT 'requested',
  ALTER COLUMN status SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rides_user_id_fkey'
  ) THEN
    ALTER TABLE rides
      ADD CONSTRAINT rides_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rides_driver_id_fkey'
  ) THEN
    ALTER TABLE rides
      ADD CONSTRAINT rides_driver_id_fkey
      FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rides_user_id ON rides(user_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver_id ON rides(driver_id);
