-- One row per browser/device that turned on daily reminders.
CREATE TABLE IF NOT EXISTS subscriptions (
  endpoint     TEXT PRIMARY KEY,   -- push service URL for this browser
  p256dh       TEXT NOT NULL,      -- browser public key (base64url)
  auth         TEXT NOT NULL,      -- browser auth secret (base64url)
  hour         INTEGER NOT NULL,   -- reminder time, local to `timezone`
  minute       INTEGER NOT NULL,
  timezone     TEXT NOT NULL,      -- IANA zone, e.g. "Australia/Sydney"
  book         TEXT NOT NULL DEFAULT 'all', -- all, bible, gita or quran
  next_send_at INTEGER NOT NULL,   -- unix ms of the next reminder
  updated_at   INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_next_send_at
  ON subscriptions (next_send_at);
