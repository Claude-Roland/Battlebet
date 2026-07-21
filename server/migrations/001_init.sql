-- BattleBet — Schema 001 (Backbone)
-- Konten, Wallet/Test-Credits, Sessions, Wetten, Teilnahmen, Läufe, Ledger.
-- Geld IMMER als *_minor BIGINT (Cent) + currency CHAR(3). Kein double.
-- Alle Wallet-Beträge sind TEST-CREDITS (is_test=true), bis die echte Geld-Schicht kommt.

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()

-- Konten ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      TEXT NOT NULL,
  username_lc   TEXT NOT NULL,               -- lower(username): Eindeutigkeit case-insensitiv
  email         TEXT,
  password_hash TEXT NOT NULL,
  display_name  TEXT NOT NULL DEFAULT '',
  tier          SMALLINT NOT NULL DEFAULT 0, -- 0=Bet Tier 1 (bronze) .. 2=Tier 3 (obsidian)
  is_test       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS users_username_lc_key ON users (username_lc);

-- Wallet (eine Zeile je Nutzer+Währung; Test-Credits) ------------------
CREATE TABLE IF NOT EXISTS wallets (
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency      CHAR(3) NOT NULL DEFAULT 'EUR',
  balance_minor BIGINT NOT NULL DEFAULT 0,
  is_test       BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, currency)
);

-- Sessions (opake Bearer-Token) ---------------------------------------
CREATE TABLE IF NOT EXISTS sessions (
  token        TEXT PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at   TIMESTAMPTZ NOT NULL,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sessions_user_idx ON sessions (user_id);

-- Wetten (Pots) --------------------------------------------------------
CREATE TABLE IF NOT EXISTS bets (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id          UUID NOT NULL REFERENCES users(id),
  name                TEXT NOT NULL,
  sport               SMALLINT NOT NULL,           -- Sport enum index
  distance_km         NUMERIC(6,2) NOT NULL,
  iterations_per_week SMALLINT NOT NULL,
  expiration_days     SMALLINT NOT NULL,
  stake_minor         BIGINT NOT NULL,
  currency            CHAR(3) NOT NULL,
  tier                SMALLINT NOT NULL DEFAULT 0, -- PotTier: 0=limited,1=limitedLarge,2=unlimited
  fee_bps             INTEGER NOT NULL DEFAULT 1000,
  tag                 SMALLINT NOT NULL DEFAULT 0,
  status              SMALLINT NOT NULL DEFAULT 0, -- 0=joining,1=running,2=resolved,3=cancelled
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(), -- echte Uhr (ersetzt createdSeq)
  entry_closes_at     TIMESTAMPTZ,                 -- Einstiegsfenster (limitierte Pots)
  ends_at             TIMESTAMPTZ,                 -- festes Enddatum
  resolved_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS bets_status_idx ON bets (status);
CREATE INDEX IF NOT EXISTS bets_created_idx ON bets (created_at DESC);

-- Teilnahmen (Nutzer in Wette) ----------------------------------------
CREATE TABLE IF NOT EXISTS participations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bet_id      UUID NOT NULL REFERENCES bets(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  state       SMALLINT NOT NULL DEFAULT 0,   -- 0=active,1=dropped,2=finished
  stake_minor BIGINT NOT NULL,               -- Einstiegspreis (flach oder Anteilswert)
  currency    CHAR(3) NOT NULL,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  settled     BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (bet_id, user_id)
);
CREATE INDEX IF NOT EXISTS part_bet_idx ON participations (bet_id);
CREATE INDEX IF NOT EXISTS part_user_idx ON participations (user_id);

-- Läufe (rohes Bündel; server-geurteilt) ------------------------------
CREATE TABLE IF NOT EXISTS runs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participation_id  UUID REFERENCES participations(id) ON DELETE SET NULL,
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bet_id            UUID REFERENCES bets(id) ON DELETE SET NULL,
  source            SMALLINT NOT NULL DEFAULT 0, -- 0=phone,1=watch
  total_meters      INTEGER NOT NULL DEFAULT 0,
  total_seconds     INTEGER NOT NULL DEFAULT 0,
  avg_pace          INTEGER NOT NULL DEFAULT 0,
  qualifying_meters INTEGER NOT NULL DEFAULT 0,
  samples           JSONB,                       -- rohe RunSamples (Samen: später signiert)
  verdict           SMALLINT,                    -- NULL=ungeprüft,0=zählt,1=abgelehnt (Server-Urteil)
  recorded_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS runs_user_idx ON runs (user_id);
CREATE INDEX IF NOT EXISTS runs_bet_idx ON runs (bet_id);

-- Ledger (Wallet-Buchungen; Audit) ------------------------------------
CREATE TABLE IF NOT EXISTS ledger (
  id                  BIGSERIAL PRIMARY KEY,
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind                SMALLINT NOT NULL, -- 0=deposit,1=withdraw,2=stake_hold,3=payout,4=forfeit,5=fee,6=refund
  amount_minor        BIGINT NOT NULL,   -- vorzeichenbehaftet (+Gutschrift, -Belastung)
  currency            CHAR(3) NOT NULL,
  bet_id              UUID REFERENCES bets(id) ON DELETE SET NULL,
  balance_after_minor BIGINT NOT NULL,
  note                TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ledger_user_idx ON ledger (user_id, created_at DESC);
