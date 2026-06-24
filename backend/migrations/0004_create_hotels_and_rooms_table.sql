CREATE TABLE IF NOT EXISTS hotels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  rating DOUBLE PRECISION NOT NULL DEFAULT 0,
  review_count INTEGER NOT NULL DEFAULT 0,
  price_per_night DOUBLE PRECISION NOT NULL DEFAULT 0,
  amenities JSONB NOT NULL DEFAULT '[]'::jsonb,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  video_360_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  type TEXT NOT NULL DEFAULT 'hotel',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE hotels
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS review_count INTEGER,
  ADD COLUMN IF NOT EXISTS price_per_night DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS amenities JSONB,
  ADD COLUMN IF NOT EXISTS image_urls JSONB,
  ADD COLUMN IF NOT EXISTS video_360_urls JSONB,
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN,
  ADD COLUMN IF NOT EXISTS type TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE hotels
SET
  description = COALESCE(description, ''),
  rating = COALESCE(rating, 0),
  review_count = COALESCE(review_count, 0),
  price_per_night = COALESCE(price_per_night, 0),
  amenities = COALESCE(amenities, '[]'::jsonb),
  image_urls = COALESCE(image_urls, '[]'::jsonb),
  video_360_urls = COALESCE(video_360_urls, '[]'::jsonb),
  is_featured = COALESCE(is_featured, false),
  type = COALESCE(NULLIF(type, ''), 'hotel');

ALTER TABLE hotels
  ALTER COLUMN description SET DEFAULT '',
  ALTER COLUMN description SET NOT NULL,
  ALTER COLUMN rating SET DEFAULT 0,
  ALTER COLUMN rating SET NOT NULL,
  ALTER COLUMN review_count SET DEFAULT 0,
  ALTER COLUMN review_count SET NOT NULL,
  ALTER COLUMN price_per_night SET DEFAULT 0,
  ALTER COLUMN price_per_night SET NOT NULL,
  ALTER COLUMN amenities SET DEFAULT '[]'::jsonb,
  ALTER COLUMN amenities SET NOT NULL,
  ALTER COLUMN image_urls SET DEFAULT '[]'::jsonb,
  ALTER COLUMN image_urls SET NOT NULL,
  ALTER COLUMN video_360_urls SET DEFAULT '[]'::jsonb,
  ALTER COLUMN video_360_urls SET NOT NULL,
  ALTER COLUMN is_featured SET DEFAULT false,
  ALTER COLUMN is_featured SET NOT NULL,
  ALTER COLUMN type SET DEFAULT 'hotel',
  ALTER COLUMN type SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_hotels_city ON hotels(city);

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
  'Placeholder pour anciennes références de chambres',
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

CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id UUID,
  room_type TEXT NOT NULL,
  capacity INTEGER NOT NULL DEFAULT 2,
  price DOUBLE PRECISION NOT NULL DEFAULT 0,
  amenities JSONB NOT NULL DEFAULT '[]'::jsonb,
  available BOOLEAN NOT NULL DEFAULT true,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  video_360_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS price_per_night DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN,
  ADD COLUMN IF NOT EXISTS hotel_id UUID,
  ADD COLUMN IF NOT EXISTS room_type TEXT,
  ADD COLUMN IF NOT EXISTS capacity INTEGER,
  ADD COLUMN IF NOT EXISTS price DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS amenities JSONB,
  ADD COLUMN IF NOT EXISTS available BOOLEAN,
  ADD COLUMN IF NOT EXISTS image_urls JSONB,
  ADD COLUMN IF NOT EXISTS video_360_urls JSONB,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE rooms
SET
  hotel_id = COALESCE(hotel_id, '00000000-0000-0000-0000-000000000001'::uuid),
  room_type = COALESCE(NULLIF(room_type, ''), NULLIF(name, ''), 'Standard'),
  capacity = COALESCE(capacity, 2),
  price = COALESCE(price, price_per_night, 0),
  amenities = COALESCE(amenities, '[]'::jsonb),
  available = COALESCE(available, is_available, true),
  image_urls = COALESCE(image_urls, '[]'::jsonb),
  video_360_urls = COALESCE(video_360_urls, '[]'::jsonb);

ALTER TABLE rooms
  ALTER COLUMN hotel_id SET NOT NULL,
  ALTER COLUMN room_type SET NOT NULL,
  ALTER COLUMN capacity SET DEFAULT 2,
  ALTER COLUMN capacity SET NOT NULL,
  ALTER COLUMN price SET DEFAULT 0,
  ALTER COLUMN price SET NOT NULL,
  ALTER COLUMN amenities SET DEFAULT '[]'::jsonb,
  ALTER COLUMN amenities SET NOT NULL,
  ALTER COLUMN available SET DEFAULT true,
  ALTER COLUMN available SET NOT NULL,
  ALTER COLUMN image_urls SET DEFAULT '[]'::jsonb,
  ALTER COLUMN image_urls SET NOT NULL,
  ALTER COLUMN video_360_urls SET DEFAULT '[]'::jsonb,
  ALTER COLUMN video_360_urls SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rooms_hotel_id_fkey'
  ) THEN
    ALTER TABLE rooms
      ADD CONSTRAINT rooms_hotel_id_fkey
      FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rooms_hotel_id ON rooms(hotel_id);
