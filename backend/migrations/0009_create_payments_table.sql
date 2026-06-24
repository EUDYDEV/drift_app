CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reservation_id UUID REFERENCES reservations(id) ON DELETE SET NULL,
    reservation_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED')),
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'XOF',
    payment_method_code TEXT NOT NULL,
    payment_method_label TEXT,
    payment_method_token TEXT,
    payment_method_last4 TEXT,
    payment_provider TEXT NOT NULL,
    provider_reference TEXT NOT NULL,
    failure_reason TEXT,
    payer_phone_number TEXT,
    payer_email TEXT,
    payer_full_name TEXT,
    payment_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    provider_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user_id
    ON payments(user_id);

CREATE INDEX IF NOT EXISTS idx_payments_reservation_id
    ON payments(reservation_id);

CREATE INDEX IF NOT EXISTS idx_payments_status
    ON payments(status);

CREATE INDEX IF NOT EXISTS idx_payments_provider_reference
    ON payments(provider_reference);
