import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
import path from 'node:path';
import { config } from '../config.js';

// Ensure data directory exists
const dataDir = path.dirname(config.db1Path);
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

export const db1 = new DatabaseSync(config.db1Path);

// Enable WAL mode and foreign keys for high performance & reliability
db1.exec('PRAGMA journal_mode = WAL;');
db1.exec('PRAGMA synchronous = NORMAL;');
db1.exec('PRAGMA foreign_keys = ON;');

export function initDb1Schema() {
  db1.exec(`
    -- Users Table (DB 1)
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL,
      username TEXT UNIQUE NOT NULL,
      crouket_id TEXT UNIQUE NOT NULL,
      avatar_url TEXT,
      created_at TEXT NOT NULL
    );

    -- Categories Table (DB 1)
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      user_id TEXT, -- NULL for default system categories
      name TEXT NOT NULL,
      emoji TEXT NOT NULL,
      color_value INTEGER NOT NULL,
      monthly_budget REAL NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    );

    -- Media Assets Metadata Table (DB 1 - Zero bloated binary data, only metadata)
    CREATE TABLE IF NOT EXISTS media_assets (
      id TEXT PRIMARY KEY,
      owner_id TEXT NOT NULL,
      sha256_hash TEXT UNIQUE NOT NULL,
      blurhash TEXT NOT NULL,
      width INTEGER NOT NULL,
      height INTEGER NOT NULL,
      original_size_bytes INTEGER NOT NULL,
      compressed_size_bytes INTEGER NOT NULL,
      compression_ratio REAL NOT NULL,
      mime_type TEXT NOT NULL DEFAULT 'image/webp',
      created_at TEXT NOT NULL,
      FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Transactions Table (DB 1)
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('expense', 'income')),
      amount REAL NOT NULL,
      category_id TEXT NOT NULL,
      caption TEXT NOT NULL DEFAULT '',
      media_id TEXT,
      is_private INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
      FOREIGN KEY (media_id) REFERENCES media_assets(id) ON DELETE SET NULL
    );

    -- Emoji Reactions Table (DB 1)
    CREATE TABLE IF NOT EXISTS reactions (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      emoji TEXT NOT NULL,
      created_at TEXT NOT NULL,
      UNIQUE(transaction_id, user_id, emoji),
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Friends Table (DB 1)
    CREATE TABLE IF NOT EXISTS friends (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      friend_id TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'accepted',
      created_at TEXT NOT NULL,
      UNIQUE(user_id, friend_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Indexes for lightning fast lookups
    CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_transactions_created ON transactions(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_media_hash ON media_assets(sha256_hash);
    CREATE INDEX IF NOT EXISTS idx_reactions_tx ON reactions(transaction_id);
    CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_id);
  `);
}

