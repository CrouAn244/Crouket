import crypto from 'node:crypto';
import { db1 } from '../db/db1_users.js';

export class CategoryController {
  static list(req, res, next) {
    try {
      const userId = req.user ? req.user.id : null;
      let sql = `
        SELECT 
          c.*,
          COALESCE(SUM(t.amount), 0) as current_spent
        FROM categories c
        LEFT JOIN transactions t ON c.id = t.category_id 
          AND t.user_id = ? 
          AND t.type = 'expense'
          AND strftime('%Y-%m', t.created_at) = strftime('%Y-%m', 'now')
        WHERE c.user_id = ? OR c.user_id IS NULL
        GROUP BY c.id
        ORDER BY c.created_at ASC
      `;

      const stmt = db1.prepare(sql);
      const rows = stmt.all(userId, userId);

      const categories = rows.map((r) => ({
        id: r.id,
        name: r.name,
        emoji: r.emoji,
        colorValue: r.color_value,
        monthlyBudget: r.monthly_budget,
        currentSpent: r.current_spent,
      }));

      res.json({ success: true, data: categories });
    } catch (err) {
      next(err);
    }
  }

  static create(req, res, next) {
    try {
      const { name, emoji, colorValue, monthlyBudget = 0 } = req.body;
      const userId = req.user.id;

      if (!name || !emoji || !colorValue) {
        return res.status(400).json({
          success: false,
          message: 'name, emoji, and colorValue are required',
        });
      }

      const id = `cat_${crypto.randomUUID().slice(0, 8)}`;
      const now = new Date().toISOString();

      const stmt = db1.prepare(`
        INSERT INTO categories (id, user_id, name, emoji, color_value, monthly_budget, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);

      stmt.run(id, userId, name, emoji, Number(colorValue), Number(monthlyBudget), now);

      res.status(201).json({
        success: true,
        message: 'Category created successfully',
        data: {
          id,
          name,
          emoji,
          colorValue: Number(colorValue),
          monthlyBudget: Number(monthlyBudget),
          currentSpent: 0,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

