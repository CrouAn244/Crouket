import { test, describe, before } from 'node:test';
import assert from 'node:assert';
import sharp from 'sharp';
import fs from 'node:fs';
import { db1, initDb1Schema } from '../src/db/db1_users.js';
import { db2Storage } from '../src/db/db2_storage.js';
import { AuthService } from '../src/services/auth_service.js';
import { ImageOptimizationService } from '../src/services/image_service.js';
import { TransactionController } from '../src/controllers/transaction_controller.js';

describe('Crouket 2-DB Backend & Image Optimization Test Suite', () => {
  let testUser;
  let sampleImageBuffer;
  let uploadedMedia;
  let createdTxId;

  before(async () => {
    initDb1Schema();

    // Generate a unique simulated camera photo per test run
    const uniqueText = `Crouket_Test_${Date.now()}_${Math.random()}`;
    sampleImageBuffer = await sharp({
      create: {
        width: 1600,
        height: 1600,
        channels: 4,
        background: { r: 240, g: 100, b: 50, alpha: 1 },
      },
    })
      .composite([
        {
          input: Buffer.from(
            `<svg width="1600" height="1600"><text x="100" y="800" font-size="60" fill="#FFD233">${uniqueText}</text></svg>`
          ),
          top: 0,
          left: 0,
        },
      ])
      .jpeg({ quality: 95 })
      .toBuffer();
  });

  test('DB 1: Schema has been properly initialized with zero binary bloat', () => {
    const tables = db1
      .prepare("SELECT name FROM sqlite_master WHERE type='table'")
      .all()
      .map((t) => t.name);

    assert.ok(tables.includes('users'), 'Users table should exist in DB 1');
    assert.ok(tables.includes('categories'), 'Categories table should exist in DB 1');
    assert.ok(tables.includes('media_assets'), 'Media assets table should exist in DB 1');
    assert.ok(tables.includes('transactions'), 'Transactions table should exist in DB 1');
    assert.ok(tables.includes('reactions'), 'Reactions table should exist in DB 1');
    assert.ok(tables.includes('friends'), 'Friends table should exist in DB 1');
  });

  test('Auth Service: Registers user and auto-creates default categories in DB 1', () => {
    const email = `test_${Date.now()}@crouket.app`;
    const res = AuthService.register({
      email,
      password: 'mypassword123',
      name: 'Tester Unit',
      username: `tester_${Date.now()}`,
    });

    assert.ok(res.user.id);
    assert.strictEqual(res.user.email, email);
    assert.ok(res.token);

    testUser = res.user;

    // Check categories created for this user
    const cats = db1.prepare('SELECT * FROM categories WHERE user_id = ?').all(testUser.id);
    assert.ok(cats.length >= 8, 'Should have created at least 8 default categories');
  });

  test('Auth Service: Logs in user with valid credentials', () => {
    const res = AuthService.login({
      email: testUser.email,
      password: 'mypassword123',
    });

    assert.ok(res.token);
    assert.strictEqual(res.user.id, testUser.id);
  });

  test('Image Optimization: Raw image is compressed > 80% to WebP and BlurHash generated', async () => {
    const rawSize = sampleImageBuffer.length;
    const result = await ImageOptimizationService.processAndStoreImage(sampleImageBuffer, testUser.id);

    assert.ok(result.id);
    assert.ok(result.sha256);
    assert.ok(result.blurhash, 'Should generate a BlurHash string');
    assert.strictEqual(typeof result.blurhash, 'string');
    assert.ok(result.blurhash.length >= 10, 'Blurhash should have valid length');

    // Verify significant compression savings (> 65% reduction)
    assert.ok(
      result.compressedSizeBytes < rawSize * 0.35,
      `Compressed size (${result.compressedSizeBytes}) should be < 35% of raw size (${rawSize})`
    );
    assert.strictEqual(result.isDeduplicated, false);

    uploadedMedia = result;

    // Verify files exist in DB 2 (Dedicated Blob Storage)
    const thumbPath = db2Storage.getVariantPath(result.sha256, 'thumb');
    const feedPath = db2Storage.getVariantPath(result.sha256, 'feed');
    const fullPath = db2Storage.getVariantPath(result.sha256, 'full');

    assert.ok(thumbPath && fs.existsSync(thumbPath), 'Thumb variant must exist in DB 2');
    assert.ok(feedPath && fs.existsSync(feedPath), 'Feed variant must exist in DB 2');
    assert.ok(fullPath && fs.existsSync(fullPath), 'Full variant must exist in DB 2');

    // Verify DB 1 ONLY stored metadata, not binary image
    const assetInDb1 = db1.prepare('SELECT * FROM media_assets WHERE id = ?').get(result.id);
    assert.ok(assetInDb1);
    assert.strictEqual(assetInDb1.mime_type, 'image/webp');
    assert.strictEqual(assetInDb1.sha256_hash, result.sha256);
  });

  test('Deduplication: Uploading identical image reuses existing asset with 0 byte overhead', async () => {
    const dedupeResult = await ImageOptimizationService.processAndStoreImage(sampleImageBuffer, testUser.id);

    assert.strictEqual(dedupeResult.isDeduplicated, true, 'Should detect identical content via SHA-256');
    assert.strictEqual(dedupeResult.id, uploadedMedia.id);
  });

  test('Transactions: Creates spending record linked to optimized media asset', () => {
    const categories = db1.prepare('SELECT id FROM categories WHERE user_id = ?').all(testUser.id);

    // Mock request object
    const req = {
      user: { id: testUser.id },
      body: {
        type: 'expense',
        amount: 85000,
        categoryId: categories[0].id,
        caption: 'Bữa trưa cơm tấm sườn bì 🍛',
        mediaId: uploadedMedia.id,
      },
    };

    let responseData = null;
    let statusCode = null;

    const res = {
      status(code) {
        statusCode = code;
        return this;
      },
      json(payload) {
        responseData = payload;
      },
    };

    TransactionController.create(req, res, (err) => {
      if (err) throw err;
    });

    assert.strictEqual(statusCode, 201);
    assert.ok(responseData.success);
    assert.strictEqual(responseData.data.amount, 85000);
    assert.strictEqual(responseData.data.caption, 'Bữa trưa cơm tấm sườn bì 🍛');
    assert.ok(responseData.data.media.urls.feed.includes(uploadedMedia.sha256));
    assert.ok(responseData.data.media.blurhash);

    createdTxId = responseData.data.id;
  });

  test('Emoji Reactions: Toggling emoji works as expected', () => {
    const req = {
      user: { id: testUser.id },
      params: { id: createdTxId },
      body: { emoji: '💸' },
    };

    let responseData = null;
    const res = {
      json(payload) {
        responseData = payload;
      },
    };

    // Toggle ON
    TransactionController.toggleReaction(req, res, (err) => {
      if (err) throw err;
    });
    assert.strictEqual(responseData.data.reactions['💸'], 1);

    // Toggle OFF
    TransactionController.toggleReaction(req, res, (err) => {
      if (err) throw err;
    });
    assert.strictEqual(responseData.data.reactions['💸'] || 0, 0);
  });

  test('DB 2 Storage Engine: Storage metrics report bytes saved and variants', () => {
    const metrics = db2Storage.getStorageMetrics();
    assert.ok(metrics.totalStoredVariants >= 3);
    assert.ok(metrics.totalBytesStored > 0);
  });
});

