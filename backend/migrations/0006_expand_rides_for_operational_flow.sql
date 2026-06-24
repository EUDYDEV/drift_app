ALTER TABLE users
  ADD COLUMN IF NOT EXISTS account_balance DOUBLE PRECISION NOT NULL DEFAULT 100000,
  ADD COLUMN IF NOT EXISTS penalty_balance DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_restricted BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS restriction_reason TEXT;

CREATE TABLE IF NOT EXISTS ride_infractions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL,
  user_id UUID NOT NULL,
  infraction_type TEXT NOT NULL,
  description TEXT NOT NULL,
  overtime_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  fine_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ride_infractions_ride_id_fkey'
  ) THEN
    ALTER TABLE ride_infractions
      ADD CONSTRAINT ride_infractions_ride_id_fkey
      FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ride_infractions_user_id_fkey'
  ) THEN
    ALTER TABLE ride_infractions
      ADD CONSTRAINT ride_infractions_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;

ALTER TABLE rides
  ADD COLUMN IF NOT EXISTS pickup_location JSONB,
  ADD COLUMN IF NOT EXISTS destination_location JSONB,
  ADD COLUMN IF NOT EXISTS ride_type TEXT NOT NULL DEFAULT 'withDriver',
  ADD COLUMN IF NOT EXISTS schedule_type TEXT NOT NULL DEFAULT 'immediate',
  ADD COLUMN IF NOT EXISTS scheduled_start TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS group_context TEXT NOT NULL DEFAULT 'soloBusiness',
  ADD COLUMN IF NOT EXISTS passenger_count INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS requested_duration_minutes INTEGER NOT NULL DEFAULT 60,
  ADD COLUMN IF NOT EXISTS vehicle_type TEXT NOT NULL DEFAULT 'comfort',
  ADD COLUMN IF NOT EXISTS seat_capacity INTEGER NOT NULL DEFAULT 4,
  ADD COLUMN IF NOT EXISTS estimated_price DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hourly_rate DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS estimated_time_text TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS overtime_minutes INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS overtime_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS final_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'included',
  ADD COLUMN IF NOT EXISTS penalty_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS restriction_reason TEXT,
  ADD COLUMN IF NOT EXISTS auto_charge_attempted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE rides
SET
  pickup_location = COALESCE(
    pickup_location,
    jsonb_build_object(
      'latitude', 0,
      'longitude', 0,
      'address', COALESCE(NULLIF(origin, ''), 'Origine inconnue'),
      'city', 'Abidjan',
      'country', 'Cote d''Ivoire'
    )
  ),
  destination_location = COALESCE(
    destination_location,
    jsonb_build_object(
      'latitude', 0,
      'longitude', 0,
      'address', COALESCE(NULLIF(destination, ''), 'Destination inconnue'),
      'city', 'Abidjan',
      'country', 'Cote d''Ivoire'
    )
  ),
  ride_type = COALESCE(NULLIF(ride_type, ''), 'withDriver'),
  schedule_type = COALESCE(NULLIF(schedule_type, ''), 'immediate'),
  group_context = COALESCE(NULLIF(group_context, ''), 'soloBusiness'),
  passenger_count = GREATEST(COALESCE(passenger_count, 1), 1),
  requested_duration_minutes = GREATEST(COALESCE(requested_duration_minutes, 60), 30),
  vehicle_type = COALESCE(NULLIF(vehicle_type, ''), 'comfort'),
  seat_capacity = GREATEST(COALESCE(seat_capacity, 4), 1),
  estimated_price = GREATEST(COALESCE(estimated_price, 0), 0),
  hourly_rate = GREATEST(COALESCE(hourly_rate, 12000), 12000),
  estimated_time_text = COALESCE(estimated_time_text, ''),
  overtime_minutes = GREATEST(COALESCE(overtime_minutes, 0), 0),
  overtime_amount = GREATEST(COALESCE(overtime_amount, 0), 0),
  final_amount = GREATEST(
    COALESCE(final_amount, estimated_price + overtime_amount + penalty_amount, 0),
    COALESCE(estimated_price, 0) + COALESCE(overtime_amount, 0) + COALESCE(penalty_amount, 0)
  ),
  payment_status = COALESCE(NULLIF(payment_status, ''), 'included'),
  penalty_amount = GREATEST(COALESCE(penalty_amount, 0), 0),
  started_at = COALESCE(started_at, scheduled_start, created_at),
  updated_at = COALESCE(updated_at, created_at, now());

ALTER TABLE rides
  ALTER COLUMN pickup_location SET DEFAULT '{"latitude":0,"longitude":0,"address":"Origine inconnue","city":"Abidjan","country":"Cote d''Ivoire"}'::jsonb,
  ALTER COLUMN pickup_location SET NOT NULL,
  ALTER COLUMN destination_location SET DEFAULT '{"latitude":0,"longitude":0,"address":"Destination inconnue","city":"Abidjan","country":"Cote d''Ivoire"}'::jsonb,
  ALTER COLUMN destination_location SET NOT NULL,
  ALTER COLUMN ride_type SET DEFAULT 'withDriver',
  ALTER COLUMN ride_type SET NOT NULL,
  ALTER COLUMN schedule_type SET DEFAULT 'immediate',
  ALTER COLUMN schedule_type SET NOT NULL,
  ALTER COLUMN group_context SET DEFAULT 'soloBusiness',
  ALTER COLUMN group_context SET NOT NULL,
  ALTER COLUMN passenger_count SET DEFAULT 1,
  ALTER COLUMN passenger_count SET NOT NULL,
  ALTER COLUMN requested_duration_minutes SET DEFAULT 60,
  ALTER COLUMN requested_duration_minutes SET NOT NULL,
  ALTER COLUMN vehicle_type SET DEFAULT 'comfort',
  ALTER COLUMN vehicle_type SET NOT NULL,
  ALTER COLUMN seat_capacity SET DEFAULT 4,
  ALTER COLUMN seat_capacity SET NOT NULL,
  ALTER COLUMN estimated_price SET DEFAULT 0,
  ALTER COLUMN estimated_price SET NOT NULL,
  ALTER COLUMN hourly_rate SET DEFAULT 0,
  ALTER COLUMN hourly_rate SET NOT NULL,
  ALTER COLUMN estimated_time_text SET DEFAULT '',
  ALTER COLUMN estimated_time_text SET NOT NULL,
  ALTER COLUMN overtime_minutes SET DEFAULT 0,
  ALTER COLUMN overtime_minutes SET NOT NULL,
  ALTER COLUMN overtime_amount SET DEFAULT 0,
  ALTER COLUMN overtime_amount SET NOT NULL,
  ALTER COLUMN final_amount SET DEFAULT 0,
  ALTER COLUMN final_amount SET NOT NULL,
  ALTER COLUMN payment_status SET DEFAULT 'included',
  ALTER COLUMN payment_status SET NOT NULL,
  ALTER COLUMN penalty_amount SET DEFAULT 0,
  ALTER COLUMN penalty_amount SET NOT NULL,
  ALTER COLUMN updated_at SET DEFAULT now(),
  ALTER COLUMN updated_at SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_scheduled_start ON rides(scheduled_start);
CREATE INDEX IF NOT EXISTS idx_ride_infractions_user_id ON ride_infractions(user_id);
