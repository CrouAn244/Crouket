import crypto from 'node:crypto';
import { db1 } from '../db/db1_users.js';
import { AuthService } from '../services/auth_service.js';

export class FriendController {
  static list(req, res, next) {
    try {
      const userId = req.user.id;
      const stmt = db1.prepare(`
        SELECT 
          u.id, u.name, u.username, u.crouket_id, u.avatar_url,
          f.created_at as friendship_date
        FROM friends f
        JOIN users u ON f.friend_id = u.id
        WHERE f.user_id = ?
        ORDER BY f.created_at DESC
      `);

      const friends = stmt.all(userId);
      res.json({
        success: true,
        data: friends.map((f) => ({
          id: f.id,
          name: f.name,
          username: f.username,
          crouketId: f.crouket_id,
          avatarUrl: f.avatar_url,
          isMutual: true,
        })),
      });
    } catch (err) {
      next(err);
    }
  }

  static addByCrouketId(req, res, next) {
    try {
      const { crouketId } = req.body;
      const userId = req.user.id;

      if (!crouketId) {
        return res.status(400).json({ success: false, message: 'crouketId is required' });
      }

      const target = AuthService.findByCrouketId(crouketId);
      if (!target) {
        return res.status(404).json({ success: false, message: `User with ID ${crouketId} not found` });
      }

      if (target.id === userId) {
        return res.status(400).json({ success: false, message: 'You cannot add yourself as a friend' });
      }

      // Check if already friends
      const checkStmt = db1.prepare('SELECT id FROM friends WHERE user_id = ? AND friend_id = ?');
      const existing = checkStmt.get(userId, target.id);
      if (existing) {
        return res.status(409).json({ success: false, message: 'Already friends' });
      }

      const now = new Date().toISOString();
      const insertStmt = db1.prepare(`
        INSERT INTO friends (id, user_id, friend_id, status, created_at)
        VALUES (?, ?, ?, 'accepted', ?)
      `);

      // Add mutual friend relation
      insertStmt.run(crypto.randomUUID(), userId, target.id, now);
      insertStmt.run(crypto.randomUUID(), target.id, userId, now);

      res.status(201).json({
        success: true,
        message: `Successfully connected with ${target.name} (${target.crouket_id})`,
        data: {
          id: target.id,
          name: target.name,
          username: target.username,
          crouketId: target.crouket_id,
          avatarUrl: target.avatar_url,
          isMutual: true,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

