-- BattleBet — Schema 004: entkoppelte Laeufe + Wochen-Checkpoint.
-- runs.sport/activity/distance_meters: der Lauf ist eigenstaendig; der Checkpoint
-- gleicht ihn gegen alle passenden Wetten ab (ein Lauf zaehlt fuer mehrere Wetten).
-- activity: 0=walking (wandern), 1=jogging, 2=running (aus dem Tempo abgeleitet).
-- bets.weeks_checked: bis zu welcher abgeschlossenen Woche schon geprueft wurde.

ALTER TABLE runs ADD COLUMN IF NOT EXISTS sport SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE runs ADD COLUMN IF NOT EXISTS activity SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE runs ADD COLUMN IF NOT EXISTS distance_meters INTEGER NOT NULL DEFAULT 0;
ALTER TABLE bets ADD COLUMN IF NOT EXISTS weeks_checked INTEGER NOT NULL DEFAULT 0;

UPDATE runs SET distance_meters = total_meters WHERE distance_meters = 0;
UPDATE runs SET activity = CASE
  WHEN avg_pace <= 0 THEN 0 WHEN avg_pace <= 360 THEN 2 WHEN avg_pace <= 540 THEN 1 ELSE 0 END;
