ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS name TEXT;

UPDATE rooms
SET name = COALESCE(NULLIF(name, ''), 'Chambre Standard')
WHERE name IS NULL;

UPDATE rooms
SET name = COALESCE(NULLIF(name, ''), NULLIF(room_type, ''), 'Chambre Standard')
WHERE btrim(COALESCE(name, '')) = '';

ALTER TABLE rooms
  ALTER COLUMN name SET DEFAULT 'Chambre Standard',
  ALTER COLUMN name SET NOT NULL;
