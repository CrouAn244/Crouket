import crypto from 'node:crypto';
import { db1 } from '../db/db1_users.js';
import { config } from '../config.js';

export class TransactionController {
  /**
   * Helper to format a transaction row into an API-ready object
   */
  static _formatTransaction(row, currentUserId = null) {
    // Get reactions
    const reactStmt = db1.prepare(`
      SELECT emoji, user_id FROM reactions WHERE transaction_id = ?
    `);
    const reactionsList = reactStmt.all(row.id);

    const reactionCounts = {};
    const myReactions = [];

    for (const r of reactionsList) {
      reactionCounts[r.emoji] = (reactionCounts[r.emoji] || 0) + 1;
      if (currentUserId && r.user_id === currentUserId) {
        myReactions.push(r.emoji);
      }
    }

    return {
      id: row.id,
      userId: row.user_id,
      type: row.type,
      amount: row.amount,
      caption: row.caption || '',
      isPrivate: Boolean(row.is_private),
      createdAt: row.created_at,
      author: {
        id: row.author_id,
        name: row.author_name,
        username: row.author_username,
        crouketId: row.author_crouket_id,
        avatarUrl: row.author_avatar_url,
      },
      category: {
        id: row.category_id,
        name: row.category_name,
        emoji: row.category_emoji,
        colorValue: row.category_color,
      },
      media: row.media_id ? {
        id: row.media_id,
        blurhash: row.media_blurhash,
        width: row.media_width,
        height: row.media_height,
        mimeType: row.media_mime_type,
        urls: {
          thumb: `${config.baseUrl}/api/media/thumb/${row.media_hash}`,
          feed: `${config.baseUrl}/api/media/feed/${row.media_hash}`,
          full: `${config.baseUrl}/api/media/full/${row.media_hash}`,
        },
      } : null,
      reactions: reactionCounts,
      myReactions,
    };
  }

  static create(req, res, next) {
    try {
      const { type, amount, categoryId, caption = '', mediaId = null, isPrivate = false } = req.body;
      const userId = req.user.id;

      if (!type || !amount || !categoryId) {
        return res.status(400).json({
          success: false,
          message: 'type (expense|income), amount, and categoryId are required',
        });
      }

      const txId = crypto.randomUUID();
      const now = new Date().toISOString();

      const insertStmt = db1.prepare(`
        INSERT INTO transactions (id, user_id, type, amount, category_id, caption, media_id, is_private, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      insertStmt.run(txId, userId, type, Number(amount), categoryId, caption, mediaId, isPrivate ? 1 : 0, now);

      const fetchStmt = db1.prepare(`
        SELECT 
          t.*,
          u.id as author_id, u.name as author_name, u.username as author_username, u.crouket_id as author_crouket_id, u.avatar_url as author_avatar_url,
          c.name as category_name, c.emoji as category_emoji, c.color_value as category_color,
          m.sha256_hash as media_hash, m.blurhash as media_blurhash, m.width as media_width, m.height as media_height, m.mime_type as media_mime_type
        FROM transactions t
        JOIN users u ON t.user_id = u.id
        JOIN categories c ON t.category_id = c.id
        LEFT JOIN media_assets m ON t.media_id = m.id
        WHERE t.id = ?
      `);

      const row = fetchStmt.get(txId);
      const formatted = TransactionController._formatTransaction(row, userId);

      res.status(201).json({
        success: true,
        message: 'Transaction created successfully',
        data: formatted,
      });
    } catch (err) {
      next(err);
    }
  }

  static getFeed(req, res, next) {
    try {
      const currentUserId = req.user ? req.user.id : null;
      const limit = Math.min(parseInt(req.query.limit || 50, 10), 100);
      const offset = parseInt(req.query.offset || 0, 10);

      // In Crouket, feed contains public posts from friends and user's own posts
      let sql = `
        SELECT 
          t.*,
          u.id as author_id, u.name as author_name, u.username as author_username, u.crouket_id as author_crouket_id, u.avatar_url as author_avatar_url,
          c.name as category_name, c.emoji as category_emoji, c.color_value as category_color,
          m.sha256_hash as media_hash, m.blurhash as media_blurhash, m.width as media_width, m.height as media_height, m.mime_type as media_mime_type
        FROM transactions t
        JOIN users u ON t.user_id = u.id
        JOIN categories c ON t.category_id = c.id
        LEFT JOIN media_assets m ON t.media_id = m.id
      `;

      if (currentUserId) {
        sql += `
          WHERE t.user_id = ? 
             OR (t.is_private = 0 AND t.user_id IN (SELECT friend_id FROM friends WHERE user_id = ?))
        `;
      } else {
        sql += ` WHERE t.is_private = 0 `;
      }

      sql += ` ORDER BY t.created_at DESC LIMIT ? OFFSET ? `;

      const stmt = db1.prepare(sql);
      const rows = currentUserId ? stmt.all(currentUserId, currentUserId, limit, offset) : stmt.all(limit, offset);

      const items = rows.map((r) => TransactionController._formatTransaction(r, currentUserId));

      res.json({
        success: true,
        data: items,
      });
    } catch (err) {
      next(err);
    }
  }

  static toggleReaction(req, res, next) {
    try {
      const { id: txId } = req.params;
      const { emoji } = req.body;
      const userId = req.user.id;

      if (!emoji) {
        return res.status(400).json({ success: false, message: 'Emoji is required' });
      }

      const existingStmt = db1.prepare(`
        SELECT id FROM reactions WHERE transaction_id = ? AND user_id = ? AND emoji = ?
      `);
      const existing = existingStmt.get(txId, userId, emoji);

      if (existing) {
        // Toggle OFF
        db1.prepare('DELETE FROM reactions WHERE id = ?').run(existing.id);
      } else {
        // Toggle ON
        const reactId = crypto.randomUUID();
        const now = new Date().toISOString();
        db1.prepare(`
          INSERT INTO reactions (id, transaction_id, user_id, emoji, created_at)
          VALUES (?, ?, ?, ?, ?)
        `).run(reactId, txId, userId, emoji, now);
      }

      // Return updated reaction counts
      const countsStmt = db1.prepare(`
        SELECT emoji, COUNT(*) as count FROM reactions WHERE transaction_id = ? GROUP BY emoji
      `);
      const counts = countsStmt.all(txId);
      const reactionsMap = {};
      for (const c of counts) {
        reactionsMap[c.emoji] = c.count;
      }

      res.json({
        success: true,
        message: existing ? 'Reaction removed' : 'Reaction added',
        data: {
          transactionId: txId,
          reactions: reactionsMap,
          toggledOn: !existing,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

