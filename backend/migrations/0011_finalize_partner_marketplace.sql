ALTER TABLE partenaires
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS wifi_ssid TEXT,
  ADD COLUMN IF NOT EXISTS wifi_password_encrypted TEXT;

UPDATE partenaires
SET
  latitude = COALESCE(latitude, NULLIF(adresse_gps ->> 'latitude', '')::DOUBLE PRECISION, 0),
  longitude = COALESCE(longitude, NULLIF(adresse_gps ->> 'longitude', '')::DOUBLE PRECISION, 0),
  adresse_gps = jsonb_build_object(
    'latitude',
    COALESCE(latitude, NULLIF(adresse_gps ->> 'latitude', '')::DOUBLE PRECISION, 0),
    'longitude',
    COALESCE(longitude, NULLIF(adresse_gps ->> 'longitude', '')::DOUBLE PRECISION, 0)
  );

ALTER TABLE partenaires
  ALTER COLUMN latitude SET DEFAULT 0,
  ALTER COLUMN latitude SET NOT NULL,
  ALTER COLUMN longitude SET DEFAULT 0,
  ALTER COLUMN longitude SET NOT NULL,
  ALTER COLUMN adresse_gps SET DEFAULT '{"latitude":0,"longitude":0}'::jsonb,
  ALTER COLUMN adresse_gps SET NOT NULL;

ALTER TABLE prestations
  ADD COLUMN IF NOT EXISTS cuisine_category TEXT,
  ADD COLUMN IF NOT EXISTS capacity INTEGER,
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS media_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS details JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE prestations
SET
  price = COALESCE(price, 0),
  is_available = COALESCE(is_available, TRUE),
  media_urls = COALESCE(media_urls, '[]'::jsonb),
  details = COALESCE(details, '{}'::jsonb);

ALTER TABLE prestations
  ALTER COLUMN price TYPE NUMERIC(12, 2) USING COALESCE(price, 0)::NUMERIC(12, 2),
  ALTER COLUMN price SET NOT NULL,
  ALTER COLUMN media_urls SET DEFAULT '[]'::jsonb,
  ALTER COLUMN media_urls SET NOT NULL,
  ALTER COLUMN details SET DEFAULT '{}'::jsonb,
  ALTER COLUMN details SET NOT NULL,
  ALTER COLUMN is_available SET DEFAULT TRUE,
  ALTER COLUMN is_available SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'prestations_capacity_check'
  ) THEN
    ALTER TABLE prestations
      ADD CONSTRAINT prestations_capacity_check CHECK (capacity IS NULL OR capacity > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'prestations_price_check'
  ) THEN
    ALTER TABLE prestations
      ADD CONSTRAINT prestations_price_check CHECK (price >= 0);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_partenaires_latitude_longitude
  ON partenaires(latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_prestations_availability_type
  ON prestations(is_available, type_service);
