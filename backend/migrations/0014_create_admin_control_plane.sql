ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users
  ADD CONSTRAINT users_role_check
  CHECK (
    role IN (
      'client',
      'driver',
      'admin',
      'SUPER_ADMIN',
      'developer',
      'manager',
      'support',
      'finance',
      'security'
    )
  );

ALTER TABLE company_vehicles
  DROP CONSTRAINT IF EXISTS company_vehicles_operational_status_check;

ALTER TABLE company_vehicles
  ADD CONSTRAINT company_vehicles_operational_status_check
  CHECK (
    operational_status IN (
      'available',
      'reserved',
      'busy',
      'maintenance',
      'offline',
      'hidden'
    )
  );

CREATE TABLE IF NOT EXISTS admin_permissions (
  permission_key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  category TEXT NOT NULL,
  risk_level TEXT NOT NULL DEFAULT 'medium',
  description TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_roles (
  role_key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  immutable BOOLEAN NOT NULL DEFAULT FALSE,
  permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_user_roles (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_key TEXT NOT NULL REFERENCES admin_roles(role_key) ON DELETE RESTRICT,
  assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_key)
);

CREATE TABLE IF NOT EXISTS admin_dashboard_layouts (
  layout_key TEXT PRIMARY KEY,
  version INTEGER NOT NULL DEFAULT 1,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  config JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_feature_flags (
  flag_key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  rollout_percentage INTEGER NOT NULL DEFAULT 0,
  audience JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT admin_feature_flags_rollout_check
    CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100)
);

CREATE TABLE IF NOT EXISTS admin_maintenance_modes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scope_type TEXT NOT NULL DEFAULT 'global',
  scope_value TEXT,
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  message TEXT NOT NULL DEFAULT '',
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  severity TEXT NOT NULL DEFAULT 'info',
  event_type TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  ip_address TEXT,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  immutable BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION admin_prevent_immutable_audit_mutation()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.immutable THEN
    RAISE EXCEPTION 'immutable admin audit event cannot be changed';
  END IF;
  IF TG_OP = 'UPDATE' THEN
    RETURN NEW;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_admin_audit_events_immutable_update ON admin_audit_events;
CREATE TRIGGER trg_admin_audit_events_immutable_update
BEFORE UPDATE ON admin_audit_events
FOR EACH ROW EXECUTE FUNCTION admin_prevent_immutable_audit_mutation();

DROP TRIGGER IF EXISTS trg_admin_audit_events_immutable_delete ON admin_audit_events;
CREATE TRIGGER trg_admin_audit_events_immutable_delete
BEFORE DELETE ON admin_audit_events
FOR EACH ROW EXECUTE FUNCTION admin_prevent_immutable_audit_mutation();

CREATE TABLE IF NOT EXISTS admin_token_revocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  partner_id UUID REFERENCES partenaires(id) ON DELETE CASCADE,
  reason TEXT NOT NULL DEFAULT '',
  revoked_by UUID REFERENCES users(id) ON DELETE SET NULL,
  revoked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS admin_security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  severity TEXT NOT NULL DEFAULT 'medium',
  category TEXT NOT NULL,
  source_ip TEXT,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  banned_until TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_internal_employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  department TEXT NOT NULL,
  title TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  open_ticket_count INTEGER NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_it_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,
  category TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'XOF',
  billing_period TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type TEXT NOT NULL,
  target_id UUID,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL DEFAULT 5,
  comment TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending',
  moderation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT admin_reviews_rating_check CHECK (rating >= 1 AND rating <= 5)
);

CREATE TABLE IF NOT EXISTS admin_pricing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  service_type TEXT NOT NULL,
  city TEXT,
  coefficient NUMERIC(8, 4) NOT NULL DEFAULT 1,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_crash_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'medium',
  title TEXT NOT NULL,
  stack_trace TEXT NOT NULL DEFAULT '',
  fingerprint TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'open',
  ai_suggestion JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_impersonation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO admin_permissions (permission_key, label, category, risk_level, description)
VALUES
  ('partners.create', 'Créer un partenaire', 'Identités & Partenaires', 'medium', 'Autorise l onboarding de nouveaux partenaires'),
  ('partners.approve', 'Approuver ou rejeter un partenaire', 'Identités & Partenaires', 'high', 'Décide si une structure peut apparaître dans Drift'),
  ('fleet.delete', 'Supprimer ou cacher un véhicule', 'Flotte', 'high', 'Peut retirer une capacité de transport'),
  ('finance.view', 'Voir les dépenses IT', 'Trésorerie', 'high', 'Accès aux coûts et marges'),
  ('security.kill_switch', 'Bannissement immédiat', 'Sécurité', 'critical', 'Révoque les sessions et désactive les catalogues associés'),
  ('security.rotate_keys', 'Rotation des clés de chiffrement', 'Sécurité', 'critical', 'Contrôle les secrets documentaires'),
  ('security.pentest', 'Lancer un pentest interne', 'Sécurité', 'high', 'Déclenche des diagnostics OWASP internes'),
  ('deploy.github', 'Déployer la mise à jour', 'CI/CD', 'critical', 'Déclenche GitHub Actions'),
  ('flags.manage', 'Gérer les feature flags', 'CI/CD', 'high', 'Active ou désactive des modules en production'),
  ('maintenance.manage', 'Mode maintenance ciblé', 'CI/CD', 'high', 'Met un service, une ville ou toute l app en maintenance'),
  ('pricing.manage', 'Modifier les règles tarifaires', 'Tarification', 'high', 'Ajuste les coefficients sans code'),
  ('reviews.moderate', 'Modérer les avis', 'Qualité', 'medium', 'Cache les commentaires frauduleux ou injurieux'),
  ('logs.view', 'Voir les logs applicatifs', 'Supervision', 'medium', 'Accès aux flux techniques'),
  ('errors.manage', 'Gérer les crashs', 'Supervision', 'medium', 'Traite les rapports d erreurs'),
  ('support.impersonate', 'Profils fantômes support', 'Support', 'critical', 'Génère un token temporaire pour reproduire un bug')
ON CONFLICT (permission_key) DO UPDATE
SET label = EXCLUDED.label,
    category = EXCLUDED.category,
    risk_level = EXCLUDED.risk_level,
    description = EXCLUDED.description;

INSERT INTO admin_roles (role_key, label, immutable, permissions)
VALUES
  ('SUPER_ADMIN', 'Créateur / Super Admin', TRUE, (
    SELECT jsonb_agg(permission_key ORDER BY permission_key) FROM admin_permissions
  )),
  ('manager', 'Manager Opérations', FALSE, '["partners.approve","flags.manage","maintenance.manage","reviews.moderate","logs.view"]'::jsonb),
  ('developer', 'Développeur E-PROJECT', FALSE, '["deploy.github","security.pentest","logs.view","errors.manage","flags.manage"]'::jsonb),
  ('finance', 'Finance', FALSE, '["finance.view","pricing.manage"]'::jsonb),
  ('support', 'Support', FALSE, '["errors.manage","support.impersonate","reviews.moderate"]'::jsonb)
ON CONFLICT (role_key) DO UPDATE
SET label = EXCLUDED.label,
    permissions = CASE WHEN admin_roles.immutable THEN admin_roles.permissions ELSE EXCLUDED.permissions END,
    updated_at = now();

INSERT INTO admin_dashboard_layouts (layout_key, version, active, config)
VALUES (
  'super_dashboard',
  1,
  TRUE,
  '{
    "title": "Centre IT Drift",
    "brand": {
      "primary": "#ff6a00",
      "surface": "#151119",
      "accent": "#321B4F"
    },
    "tabs": [
      {
        "key": "identity",
        "label": "Identités",
        "icon": "admin_panel_settings",
        "permission": "partners.approve",
        "components": ["rbac_matrix", "partner_onboarding", "employee_board", "kill_switch"]
      },
      {
        "key": "security",
        "label": "Cyber Défense",
        "icon": "security",
        "permission": "security.pentest",
        "components": ["siem", "encryption_health", "anonymization", "pentest"]
      },
      {
        "key": "delivery",
        "label": "CI/CD",
        "icon": "rocket_launch",
        "permission": "deploy.github",
        "components": ["github_deploy", "feature_flags", "maintenance"]
      },
      {
        "key": "finance",
        "label": "Trésorerie",
        "icon": "show_chart",
        "permission": "finance.view",
        "components": ["cashflow_chart", "it_expenses", "reviews", "pricing_rules"]
      },
      {
        "key": "observability",
        "label": "Logs & Erreurs",
        "icon": "terminal",
        "permission": "errors.manage",
        "components": ["live_logs", "crash_reports", "shadow_dev", "impersonation"]
      },
      {
        "key": "capacity",
        "label": "Alertes Logistiques",
        "icon": "directions_bus",
        "permission": "logs.view",
        "components": ["predictive_capacity_alerts"]
      }
    ]
  }'::jsonb
)
ON CONFLICT (layout_key) DO UPDATE
SET config = EXCLUDED.config,
    version = admin_dashboard_layouts.version + 1,
    active = TRUE,
    updated_at = now();

INSERT INTO admin_feature_flags (flag_key, label, description, enabled, rollout_percentage, audience)
VALUES
  ('hotels_module', 'Module Hôtels', 'Activation progressive du catalogue hôtelier', TRUE, 100, '{"cities":["Abidjan","Assinie","Yamoussoukro"]}'::jsonb),
  ('drift_gastronomie', 'Drift Gastronomie', 'Flux repas partenaires', TRUE, 100, '{"services":["restaurant","plat_livraison"]}'::jsonb),
  ('self_drive', 'Sans Chauffeur', 'Location sans chauffeur après vérification documentaire', TRUE, 25, '{"requiresVerifiedDocuments":true}'::jsonb),
  ('admin_shadow_dev', 'Shadow Dev', 'Suggestions de correctifs IA dans le dashboard', TRUE, 100, '{}'::jsonb)
ON CONFLICT (flag_key) DO UPDATE
SET label = EXCLUDED.label,
    description = EXCLUDED.description,
    updated_at = now();

INSERT INTO admin_maintenance_modes (scope_type, scope_value, enabled, message)
SELECT 'global', NULL, FALSE, 'Drift revient dans quelques minutes.'
WHERE NOT EXISTS (SELECT 1 FROM admin_maintenance_modes WHERE scope_type = 'global' AND scope_value IS NULL);

CREATE INDEX IF NOT EXISTS idx_admin_audit_events_created_at
  ON admin_audit_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_token_revocations_user_revoked
  ON admin_token_revocations(user_id, revoked_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_security_events_status_created
  ON admin_security_events(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_crash_reports_status_created
  ON admin_crash_reports(status, created_at DESC);
