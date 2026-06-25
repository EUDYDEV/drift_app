ALTER TABLE users
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'client',
  ADD COLUMN IF NOT EXISTS identity_documents_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driving_license_status TEXT NOT NULL DEFAULT 'missing';

UPDATE users
SET
  role = COALESCE(NULLIF(role, ''), 'client'),
  driving_license_status = COALESCE(NULLIF(driving_license_status, ''), 'missing');

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_role_check'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_role_check
      CHECK (role IN ('client', 'driver', 'admin'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_driving_license_status_check'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_driving_license_status_check
      CHECK (driving_license_status IN ('missing', 'pending', 'verified', 'rejected'));
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS company_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES partenaires(id) ON DELETE CASCADE,
  prestation_id UUID REFERENCES prestations(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  vehicle_type TEXT NOT NULL,
  registration_number TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '',
  capacity INTEGER NOT NULL DEFAULT 4,
  hourly_rate NUMERIC(12, 2) NOT NULL DEFAULT 0,
  media_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  operational_status TEXT NOT NULL DEFAULT 'available',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT company_vehicles_company_registration_unique
    UNIQUE (company_id, registration_number),
  CONSTRAINT company_vehicles_capacity_check CHECK (capacity > 0),
  CONSTRAINT company_vehicles_hourly_rate_check CHECK (hourly_rate >= 0),
  CONSTRAINT company_vehicles_operational_status_check
    CHECK (operational_status IN ('available', 'reserved', 'busy', 'maintenance', 'offline'))
);

CREATE TABLE IF NOT EXISTS company_drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES partenaires(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  driver_profile_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
  default_vehicle_id UUID REFERENCES company_vehicles(id) ON DELETE SET NULL,
  employee_reference TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT company_drivers_company_user_unique UNIQUE (company_id, user_id)
);

ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS company_id UUID,
  ADD COLUMN IF NOT EXISTS vehicle_id UUID;

ALTER TABLE rides
  ADD COLUMN IF NOT EXISTS company_id UUID,
  ADD COLUMN IF NOT EXISTS vehicle_id UUID,
  ADD COLUMN IF NOT EXISTS assigned_driver_user_id UUID,
  ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS pack_timeline JSONB NOT NULL DEFAULT '[]'::jsonb;

UPDATE rides
SET pack_timeline = COALESCE(pack_timeline, '[]'::jsonb);

CREATE TABLE IF NOT EXISTS user_identity_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  original_file_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  encrypted_content BYTEA NOT NULL,
  content_sha256 TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT user_identity_documents_user_type_unique UNIQUE (user_id, document_type),
  CONSTRAINT user_identity_documents_type_check
    CHECK (document_type IN ('driving_license', 'identity_card', 'passport')),
  CONSTRAINT user_identity_documents_status_check
    CHECK (status IN ('pending', 'verified', 'rejected'))
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'drivers_user_id_fkey'
  ) THEN
    ALTER TABLE drivers
      ADD CONSTRAINT drivers_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'drivers_company_id_fkey'
  ) THEN
    ALTER TABLE drivers
      ADD CONSTRAINT drivers_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES partenaires(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'drivers_vehicle_id_fkey'
  ) THEN
    ALTER TABLE drivers
      ADD CONSTRAINT drivers_vehicle_id_fkey
      FOREIGN KEY (vehicle_id) REFERENCES company_vehicles(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'rides_company_id_fkey'
  ) THEN
    ALTER TABLE rides
      ADD CONSTRAINT rides_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES partenaires(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'rides_vehicle_id_fkey'
  ) THEN
    ALTER TABLE rides
      ADD CONSTRAINT rides_vehicle_id_fkey
      FOREIGN KEY (vehicle_id) REFERENCES company_vehicles(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'rides_assigned_driver_user_id_fkey'
  ) THEN
    ALTER TABLE rides
      ADD CONSTRAINT rides_assigned_driver_user_id_fkey
      FOREIGN KEY (assigned_driver_user_id) REFERENCES users(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_drivers_user_id_unique
  ON drivers(user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_company_vehicles_company_status
  ON company_vehicles(company_id, operational_status, is_available);

CREATE INDEX IF NOT EXISTS idx_company_drivers_company_active
  ON company_drivers(company_id, is_active);

CREATE INDEX IF NOT EXISTS idx_company_drivers_user_id
  ON company_drivers(user_id);

CREATE INDEX IF NOT EXISTS idx_rides_company_id
  ON rides(company_id);

CREATE INDEX IF NOT EXISTS idx_rides_vehicle_id
  ON rides(vehicle_id);

CREATE INDEX IF NOT EXISTS idx_rides_assigned_driver_active
  ON rides(assigned_driver_user_id, status);

CREATE INDEX IF NOT EXISTS idx_user_identity_documents_user_status
  ON user_identity_documents(user_id, status);
