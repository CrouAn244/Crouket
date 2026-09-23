import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { db1 } from '../db/db1_users.js';
import { config } from '../config.js';

export class AuthService {
  static hashPassword(password) {
    return bcrypt.hashSync(password, 10);
  }

  static comparePassword(password, hash) {
    return bcrypt.compareSync(password, hash);
  }

  static generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        email: user.email,
        username: user.username,
        crouket_id: user.crouket_id,
      },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn }
    );
  }

  static verifyToken(token) {
    try {
      return jwt.verify(token, config.jwtSecret);
    } catch {
      return null;
    }
  }

  static findByEmail(email) {
    const stmt = db1.prepare('SELECT * FROM users WHERE LOWER(email) = LOWER(?)');
    return stmt.get(email);
  }

  static findById(id) {
    const stmt = db1.prepare('SELECT id, email, name, username, crouket_id, avatar_url, created_at FROM users WHERE id = ?');
    return stmt.get(id);
  }

  static findByCrouketId(crouketId) {
    const cleanId = crouketId.startsWith('@') ? crouketId : `@${crouketId}`;
    const stmt = db1.prepare('SELECT id, email, name, username, crouket_id, avatar_url FROM users WHERE LOWER(crouket_id) = LOWER(?)');
    return stmt.get(cleanId);
  }

  static register({ email, password, name, username }) {
    const existing = this.findByEmail(email);
    if (existing) {
      throw new Error('Email already registered');
    }

    const userId = crypto.randomUUID();
    const crouketId = `@${username.toLowerCase().replace(/[^a-z0-9_]/g, '')}`;
    const passwordHash = this.hashPassword(password);
    const now = new Date().toISOString();

    const insertUser = db1.prepare(`
      INSERT INTO users (id, email, password_hash, name, username, crouket_id, avatar_url, created_at)
      VALUES (?, ?, ?, ?, ?, ?, NULL, ?)
    `);

    insertUser.run(userId, email, passwordHash, name, username, crouketId, now);

    // Initialize default categories for this user
    this._createDefaultCategories(userId);

    const user = this.findById(userId);
    const token = this.generateToken(user);
    return { user, token };
  }

  static login({ email, password }) {
    const user = this.findByEmail(email);
    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isValid = this.comparePassword(password, user.password_hash);
    if (!isValid) {
      throw new Error('Invalid email or password');
    }

    const token = this.generateToken(user);
    const safeUser = this.findById(user.id);
    return { user: safeUser, token };
  }

  static _createDefaultCategories(userId) {
    const defaultCats = [
      { id: `cat_eat_${userId.slice(0, 8)}`, name: 'Ăn uống', emoji: '🍔', color: 0xFFFF5252, budget: 3000000 },
      { id: `cat_coffee_${userId.slice(0, 8)}`, name: 'Cà phê', emoji: '☕', color: 0xFFFF9800, budget: 1000000 },
      { id: `cat_shop_${userId.slice(0, 8)}`, name: 'Mua sắm', emoji: '🛍️', color: 0xFFAB47BC, budget: 2000000 },
      { id: `cat_transport_${userId.slice(0, 8)}`, name: 'Di chuyển', emoji: '🛵', color: 0xFF29B6F6, budget: 800000 },
      { id: `cat_entertainment_${userId.slice(0, 8)}`, name: 'Giải trí', emoji: '🎮', color: 0xFF26A69A, budget: 1500000 },
      { id: `cat_bills_${userId.slice(0, 8)}`, name: 'Hoá đơn', emoji: '💡', color: 0xFFFFA726, budget: 2500000 },
      { id: `cat_salary_${userId.slice(0, 8)}`, name: 'Lương & Thưởng', emoji: '💰', color: 0xFF66BB6A, budget: 0 },
      { id: `cat_other_${userId.slice(0, 8)}`, name: 'Khác', emoji: '📦', color: 0xFF78909C, budget: 1000000 },
    ];

    const insertCat = db1.prepare(`
      INSERT INTO categories (id, user_id, name, emoji, color_value, monthly_budget, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    const now = new Date().toISOString();
    for (const cat of defaultCats) {
      insertCat.run(cat.id, userId, cat.name, cat.emoji, cat.color, cat.budget, now);
    }
  }
}

