CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  room_id UUID,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE reservations
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS room_id UUID,
  ADD COLUMN IF NOT EXISTS start_date DATE,
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

INSERT INTO users (email, full_name, password_hash)
VALUES ('legacy-import@drift.local', 'Legacy Import', 'legacy-import')
ON CONFLICT (email) DO NOTHING;

INSERT INTO hotels (
  id,
  name,
  address,
  city,
  description,
  rating,
  review_count,
  price_per_night,
  amenities,
  image_urls,
  video_360_urls,
  is_featured,
  type
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Legacy Hotel',
  'Adresse inconnue',
  'Abidjan',
  'Placeholder pour anciennes réservations',
  0,
  0,
  0,
  '[]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb,
  false,
  'hotel'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO rooms (
  id,
  hotel_id,
  name,
  room_type,
  capacity,
  price,
  amenities,
  available,
  image_urls,
  video_360_urls
)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'Legacy Room',
  'Legacy Room',
  1,
  0,
  '[]'::jsonb,
  true,
  '[]'::jsonb,
  '[]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

UPDATE reservations
SET user_id = legacy.id
FROM (
  SELECT id
  FROM users
  WHERE email = 'legacy-import@drift.local'
  LIMIT 1
) AS legacy
WHERE reservations.user_id IS NULL;

UPDATE reservations
SET room_id = '00000000-0000-0000-0000-000000000002'
WHERE room_id IS NULL;

UPDATE reservations
SET
  start_date = COALESCE(start_date, CURRENT_DATE),
  end_date = COALESCE(end_date, CURRENT_DATE + 1);

ALTER TABLE reservations
  ALTER COLUMN user_id SET NOT NULL,
  ALTER COLUMN room_id SET NOT NULL,
  ALTER COLUMN start_date SET NOT NULL,
  ALTER COLUMN end_date SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reservations_user_id_fkey'
  ) THEN
    ALTER TABLE reservations
      ADD CONSTRAINT reservations_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reservations_room_id_fkey'
  ) THEN
    ALTER TABLE reservations
      ADD CONSTRAINT reservations_room_id_fkey
      FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reservations_user_id ON reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_room_id ON reservations(room_id);
