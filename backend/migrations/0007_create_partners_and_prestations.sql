DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'partner_type_enum'
  ) THEN
    CREATE TYPE partner_type_enum AS ENUM (
      'transport',
      'hotel',
      'restaurant',
      'cinema',
      'loisir'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'service_type_enum'
  ) THEN
    CREATE TYPE service_type_enum AS ENUM (
      'location_voiture',
      'chambre_hotel',
      'table_resto',
      'plat_livraison',
      'ticket_cinema',
      'ticket_jeu'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS partenaires (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom_entreprise TEXT NOT NULL,
  registre_commerce TEXT NOT NULL UNIQUE,
  telephone TEXT NOT NULL UNIQUE,
  adresse_gps JSONB NOT NULL DEFAULT '{"latitude":0,"longitude":0}'::jsonb,
  type_partenaire partner_type_enum NOT NULL,
  is_boosted BOOLEAN NOT NULL DEFAULT FALSE,
  wifi_ssid TEXT,
  wifi_password_encrypted TEXT,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS prestations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partenaire_id UUID NOT NULL,
  type_service service_type_enum NOT NULL,
  name TEXT NOT NULL,
  price NUMERIC(12, 2) NOT NULL,
  cuisine_category TEXT,
  capacity INTEGER,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  media_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT prestations_capacity_check CHECK (capacity IS NULL OR capacity > 0),
  CONSTRAINT prestations_price_check CHECK (price >= 0)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'prestations_partenaire_id_fkey'
  ) THEN
    ALTER TABLE prestations
      ADD CONSTRAINT prestations_partenaire_id_fkey
      FOREIGN KEY (partenaire_id) REFERENCES partenaires(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_partenaires_type_partenaire ON partenaires(type_partenaire);
CREATE INDEX IF NOT EXISTS idx_partenaires_is_boosted ON partenaires(is_boosted);
CREATE INDEX IF NOT EXISTS idx_prestations_partenaire_id ON prestations(partenaire_id);
CREATE INDEX IF NOT EXISTS idx_prestations_type_service ON prestations(type_service);
CREATE INDEX IF NOT EXISTS idx_prestations_cuisine_category ON prestations(cuisine_category);
CREATE INDEX IF NOT EXISTS idx_prestations_is_available ON prestations(is_available);
