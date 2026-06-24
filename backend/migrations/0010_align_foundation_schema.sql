ALTER TABLE users
  ADD COLUMN IF NOT EXISTS active_fine_amount DOUBLE PRECISION NOT NULL DEFAULT 0;

UPDATE users
SET active_fine_amount = GREATEST(
  COALESCE(active_fine_amount, 0),
  COALESCE(penalty_balance, 0)
);

ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS price NUMERIC(12, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS capacity INTEGER NOT NULL DEFAULT 4;

UPDATE drivers
SET
  price = CASE
    WHEN COALESCE(price, 0) > 0 THEN price
    WHEN LOWER(COALESCE(vehicle_type, '')) IN ('mini-car', 'minicar', 'mini_car') THEN 45000
    WHEN LOWER(COALESCE(vehicle_type, '')) = 'premium' THEN 25000
    WHEN LOWER(COALESCE(vehicle_type, '')) = 'economy' THEN 12000
    ELSE 18000
  END,
  capacity = CASE
    WHEN LOWER(COALESCE(vehicle_type, '')) IN ('mini-car', 'minicar', 'mini_car') THEN GREATEST(COALESCE(capacity, 30), 30)
    ELSE GREATEST(COALESCE(capacity, 4), 1)
  END;

ALTER TABLE drivers
  ALTER COLUMN price TYPE NUMERIC(12, 2) USING COALESCE(price, 0)::NUMERIC(12, 2),
  ALTER COLUMN price SET DEFAULT 0,
  ALTER COLUMN price SET NOT NULL,
  ALTER COLUMN capacity SET DEFAULT 4,
  ALTER COLUMN capacity SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'drivers_capacity_check'
  ) THEN
    ALTER TABLE drivers
      ADD CONSTRAINT drivers_capacity_check CHECK (capacity > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'drivers_price_check'
  ) THEN
    ALTER TABLE drivers
      ADD CONSTRAINT drivers_price_check CHECK (price >= 0);
  END IF;
END $$;

ALTER TABLE hotels
  ADD COLUMN IF NOT EXISTS capacity INTEGER NOT NULL DEFAULT 2,
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS wifi_ssid TEXT,
  ADD COLUMN IF NOT EXISTS wifi_password_encrypted TEXT;

UPDATE hotels
SET
  capacity = GREATEST(COALESCE(capacity, 2), 1),
  latitude = COALESCE(latitude, 0),
  longitude = COALESCE(longitude, 0);

ALTER TABLE hotels
  ALTER COLUMN price_per_night TYPE NUMERIC(12, 2) USING COALESCE(price_per_night, 0)::NUMERIC(12, 2),
  ALTER COLUMN price_per_night SET DEFAULT 0,
  ALTER COLUMN price_per_night SET NOT NULL,
  ALTER COLUMN capacity SET DEFAULT 2,
  ALTER COLUMN capacity SET NOT NULL,
  ALTER COLUMN latitude SET DEFAULT 0,
  ALTER COLUMN latitude SET NOT NULL,
  ALTER COLUMN longitude SET DEFAULT 0,
  ALTER COLUMN longitude SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'hotels_capacity_check'
  ) THEN
    ALTER TABLE hotels
      ADD CONSTRAINT hotels_capacity_check CHECK (capacity > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'hotels_price_per_night_check'
  ) THEN
    ALTER TABLE hotels
      ADD CONSTRAINT hotels_price_per_night_check CHECK (price_per_night >= 0);
  END IF;
END $$;

ALTER TABLE rooms
  ALTER COLUMN price TYPE NUMERIC(12, 2) USING COALESCE(price, 0)::NUMERIC(12, 2),
  ALTER COLUMN price SET DEFAULT 0,
  ALTER COLUMN price SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rooms_capacity_check'
  ) THEN
    ALTER TABLE rooms
      ADD CONSTRAINT rooms_capacity_check CHECK (capacity > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rooms_price_check'
  ) THEN
    ALTER TABLE rooms
      ADD CONSTRAINT rooms_price_check CHECK (price >= 0);
  END IF;
END $$;

ALTER TABLE reservations
  ADD COLUMN IF NOT EXISTS hotel_id UUID,
  ADD COLUMN IF NOT EXISTS price NUMERIC(12, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS capacity INTEGER NOT NULL DEFAULT 1;

UPDATE reservations r
SET
  hotel_id = COALESCE(r.hotel_id, rm.hotel_id),
  price = COALESCE(NULLIF(r.price, 0), rm.price, 0),
  capacity = GREATEST(COALESCE(r.capacity, rm.capacity, 1), 1)
FROM rooms rm
WHERE rm.id = r.room_id;

ALTER TABLE reservations
  ALTER COLUMN hotel_id SET NOT NULL,
  ALTER COLUMN price TYPE NUMERIC(12, 2) USING COALESCE(price, 0)::NUMERIC(12, 2),
  ALTER COLUMN price SET DEFAULT 0,
  ALTER COLUMN price SET NOT NULL,
  ALTER COLUMN capacity SET DEFAULT 1,
  ALTER COLUMN capacity SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reservations_hotel_id_fkey'
  ) THEN
    ALTER TABLE reservations
      ADD CONSTRAINT reservations_hotel_id_fkey
      FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reservations_capacity_check'
  ) THEN
    ALTER TABLE reservations
      ADD CONSTRAINT reservations_capacity_check CHECK (capacity > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reservations_price_check'
  ) THEN
    ALTER TABLE reservations
      ADD CONSTRAINT reservations_price_check CHECK (price >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'reservations_dates_check'
  ) THEN
    ALTER TABLE reservations
      ADD CONSTRAINT reservations_dates_check CHECK (end_date >= start_date);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reservations_hotel_id ON reservations(hotel_id);

ALTER TABLE partenaires
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

UPDATE partenaires
SET
  latitude = COALESCE(latitude, NULLIF(adresse_gps ->> 'latitude', '')::DOUBLE PRECISION, 0),
  longitude = COALESCE(longitude, NULLIF(adresse_gps ->> 'longitude', '')::DOUBLE PRECISION, 0);

ALTER TABLE partenaires
  ALTER COLUMN latitude SET DEFAULT 0,
  ALTER COLUMN latitude SET NOT NULL,
  ALTER COLUMN longitude SET DEFAULT 0,
  ALTER COLUMN longitude SET NOT NULL;
