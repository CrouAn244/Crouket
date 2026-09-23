import { db1, initDb1Schema } from './db1_users.js';
import { AuthService } from '../services/auth_service.js';

export function runSeed() {
  initDb1Schema();

  const userCount = db1.prepare('SELECT COUNT(*) as count FROM users').get().count;
  if (userCount > 0) {
    console.log('[Seed] Database 1 already contains data, skipping seed.');
    return;
  }

  console.log('[Seed] Seeding initial users and relationships into DB 1...');

  // 1. Create main test user
  const mainUser = AuthService.register({
    email: 'crou_an@gmail.com',
    password: 'password123',
    name: 'Crou An',
    username: 'crou_an',
  });

  // 2. Create friend users
  const friend1 = AuthService.register({
    email: 'minh_anh@gmail.com',
    password: 'password123',
    name: 'Minh Anh',
    username: 'minh_anh',
  });

  const friend2 = AuthService.register({
    email: 'duc_huy@gmail.com',
    password: 'password123',
    name: 'Đức Huy',
    username: 'duc_huy',
  });

  const friend3 = AuthService.register({
    email: 'hoang_nam@gmail.com',
    password: 'password123',
    name: 'Hoàng Nam',
    username: 'hoang_nam',
  });

  // 3. Connect mutual friendships
  const insertFriend = db1.prepare(`
    INSERT OR IGNORE INTO friends (id, user_id, friend_id, status, created_at)
    VALUES (?, ?, ?, 'accepted', ?)
  `);
  const now = new Date().toISOString();

  insertFriend.run('fr_1', mainUser.user.id, friend1.user.id, now);
  insertFriend.run('fr_2', friend1.user.id, mainUser.user.id, now);

  insertFriend.run('fr_3', mainUser.user.id, friend2.user.id, now);
  insertFriend.run('fr_4', friend2.user.id, mainUser.user.id, now);

  insertFriend.run('fr_5', mainUser.user.id, friend3.user.id, now);
  insertFriend.run('fr_6', friend3.user.id, mainUser.user.id, now);

  // 4. Find categories for sample transactions
  const catRows = db1.prepare('SELECT id, name FROM categories WHERE user_id = ?').all(mainUser.user.id);
  const catMap = {};
  for (const c of catRows) {
    catMap[c.name] = c.id;
  }

  // 5. Seed sample transactions
  const insertTx = db1.prepare(`
    INSERT INTO transactions (id, user_id, type, amount, category_id, caption, media_id, is_private, created_at)
    VALUES (?, ?, ?, ?, ?, ?, NULL, 0, ?)
  `);

  const tx1Id = 'seed_tx_1';
  insertTx.run(
    tx1Id,
    friend1.user.id,
    'expense',
    65000,
    catMap['Cà phê'] || catRows[0].id,
    'Cold brew cam sả sáng thứ 4 ☕🍊',
    new Date(Date.now() - 25 * 60 * 1000).toISOString()
  );

  const tx2Id = 'seed_tx_2';
  insertTx.run(
    tx2Id,
    friend2.user.id,
    'expense',
    189000,
    catMap['Ăn uống'] || catRows[0].id,
    'Lẩu tokbokki siêu cay cùng team 🍲',
    new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
  );

  const tx3Id = 'seed_tx_3';
  insertTx.run(
    tx3Id,
    mainUser.user.id,
    'expense',
    1450000,
    catMap['Mua sắm'] || catRows[0].id,
    'Săn sale giày chạy bộ cuối tuần 👟',
    new Date(Date.now() - 14 * 60 * 60 * 1000).toISOString()
  );

  const tx4Id = 'seed_tx_4';
  insertTx.run(
    tx4Id,
    mainUser.user.id,
    'income',
    18500000,
    catMap['Lương & Thưởng'] || catRows[0].id,
    'Ting ting lương về đầu tháng! 💰🎉',
    new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString()
  );

  // 6. Seed sample emoji reactions
  const insertReaction = db1.prepare(`
    INSERT INTO reactions (id, transaction_id, user_id, emoji, created_at)
    VALUES (?, ?, ?, ?, ?)
  `);

  insertReaction.run('r_1', tx1Id, mainUser.user.id, '💸', now);
  insertReaction.run('r_2', tx1Id, friend2.user.id, '☕', now);
  insertReaction.run('r_3', tx2Id, mainUser.user.id, '🤤', now);
  insertReaction.run('r_4', tx2Id, friend1.user.id, '🔥', now);
  insertReaction.run('r_5', tx4Id, friend1.user.id, '👏', now);
  insertReaction.run('r_6', tx4Id, friend2.user.id, '🔥', now);

  console.log('[Seed] Database 1 seeded successfully!');
}

// Allow direct execution
if (process.argv[1]?.endsWith('seed.js')) {
  runSeed();
}

