-- BattleBet — Schema 005: Bookmarks (Merkzettel) pro Nutzer.
CREATE TABLE IF NOT EXISTS bookmarks (
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bet_id     UUID NOT NULL REFERENCES bets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, bet_id)
);
CREATE INDEX IF NOT EXISTS bookmarks_user_idx ON bookmarks (user_id);
