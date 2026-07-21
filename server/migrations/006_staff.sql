-- 006_staff.sql — Personal-Kennung fuer die Admin-Seite (admin.battlebet.app).
-- Ein Konto mit is_staff = true darf kuratierte Wetten anlegen und frei benennen.
-- Re-runnable (IF NOT EXISTS), passend zum bin/migrate.dart-Runner, der ALLE
-- migrations/*.sql jedes Mal der Reihe nach anwendet.

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_staff BOOLEAN NOT NULL DEFAULT false;
