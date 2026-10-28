-- Adds the holy book chosen for each reminder ("all", "bible", "gita" or
-- "quran") to databases created before it existed. Run once:
--   npm run db:migrate
ALTER TABLE subscriptions ADD COLUMN book TEXT NOT NULL DEFAULT 'all';
