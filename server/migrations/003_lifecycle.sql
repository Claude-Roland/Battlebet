-- BattleBet — Schema 003: Einstieg-Lebenszyklus.
-- starts_at = wann das Pensum beginnt (limitiert: Anmeldeschluss; offen: sofort).
-- min_participants = Mindestteilnehmer fuer den Start (sonst Absage + Rueckzahlung).
-- Status: 0=gathering (Anmeldefenster), 1=running, 2=resolved, 3=cancelled.

ALTER TABLE bets ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ;
ALTER TABLE bets ADD COLUMN IF NOT EXISTS min_participants INTEGER NOT NULL DEFAULT 3;

-- Bestandsdaten: Startzeit = Erstellzeit.
UPDATE bets SET starts_at = created_at WHERE starts_at IS NULL;
-- Demo-Wetten des Haus-Nutzers als laufend darstellen (etablierte Pots).
UPDATE bets SET status = 1
WHERE creator_id = (SELECT id FROM users WHERE username_lc = 'battlebet')
  AND status = 0;
