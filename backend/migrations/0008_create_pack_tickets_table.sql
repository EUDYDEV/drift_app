CREATE TABLE IF NOT EXISTS pack_tickets (
    ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES partenaires(id) ON DELETE SET NULL,
    prestation_id UUID REFERENCES prestations(id) ON DELETE SET NULL,
    cart_item_id TEXT NOT NULL,
    service_type TEXT NOT NULL,
    name TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'issued',
    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    reservation_start TIMESTAMPTZ,
    reservation_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pack_tickets_user_id
    ON pack_tickets(user_id);

CREATE INDEX IF NOT EXISTS idx_pack_tickets_partner_id
    ON pack_tickets(partner_id);

CREATE INDEX IF NOT EXISTS idx_pack_tickets_prestation_id
    ON pack_tickets(prestation_id);
