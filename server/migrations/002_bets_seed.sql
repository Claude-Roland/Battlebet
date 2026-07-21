-- BattleBet — Schema 002: Seed-Spalten fuer lebendige Demo-Wetten + Haus-Nutzer + Beispiel-Wetten.
-- seed_starters/seed_dropouts sind NUR kosmetisch (Marktplatz-Gefuehl); die Aufloesung zahlt
-- ausschliesslich ECHTE Teilnehmer aus (participations). Idempotent.

ALTER TABLE bets ADD COLUMN IF NOT EXISTS seed_starters INTEGER NOT NULL DEFAULT 0;
ALTER TABLE bets ADD COLUMN IF NOT EXISTS seed_dropouts INTEGER NOT NULL DEFAULT 0;

-- Haus-Nutzer (kann sich nicht anmelden: unbrauchbarer Hash), traegt die Demo-Wetten.
INSERT INTO users (username, username_lc, password_hash, display_name, tier, is_test)
SELECT 'BattleBet', 'battlebet', 'x-not-loginable', 'BattleBet', 2, true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username_lc = 'battlebet');

-- Demo-Wetten (nur einmal je Name), gespiegelt aus sample_bets.dart. Nur EUR ist im
-- Testmodus beitretbar; adidas (USD) bleibt vorerst zum Ansehen.
INSERT INTO bets (creator_id, name, sport, distance_km, iterations_per_week, expiration_days,
                  stake_minor, currency, tier, fee_bps, tag, status, ends_at, entry_closes_at,
                  seed_starters, seed_dropouts)
SELECT h.id, v.name, v.sport, v.dist, v.ipw, v.days, v.stake, v.cur, v.tier, 1000, v.tag, 0,
       now() + make_interval(days => v.days),
       CASE WHEN v.tier < 2 THEN now() + interval '7 days' ELSE NULL END,
       v.ss, v.sd
FROM (VALUES
  ('Dominator',        0,   7.0, 2,  10, 1000, 'EUR', 0, 0,  38,   8),
  ('Tribun 11',        0,   7.5, 3, 303, 4500, 'EUR', 1, 0,  30,  18),
  ('GetAll',           0,   7.0, 4,  12, 2000, 'EUR', 0, 0,  25,  12),
  ('adidas Summerrun', 0,   8.0, 1, 126,  100, 'USD', 0, 2, 320, 300),
  ('UniversityRun19',  0, 198.5, 2,  23, 5000, 'EUR', 2, 0, 100,  88),
  ('RunRunRun',        0,   9.0, 7, 356, 3000, 'EUR', 1, 0,  45,   6),
  ('Bellymelters',     0,  14.0, 2, 165, 8000, 'EUR', 1, 0,  20,   7)
) AS v(name, sport, dist, ipw, days, stake, cur, tier, tag, ss, sd)
CROSS JOIN (SELECT id FROM users WHERE username_lc = 'battlebet') h
WHERE NOT EXISTS (
  SELECT 1 FROM bets b
  WHERE b.name = v.name
    AND b.creator_id = (SELECT id FROM users WHERE username_lc = 'battlebet')
);
