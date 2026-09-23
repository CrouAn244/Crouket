import crypto from 'node:crypto';
import sharp from 'sharp';
import { encode as encodeBlurhash } from 'blurhash';
import { db1 } from '../db/db1_users.js';
import { db2Storage } from '../db/db2_storage.js';
import { config } from '../config.js';

export class ImageOptimizationService {
  /**
   * Computes SHA-256 hash of buffer for content-addressed deduplication
   */
  static computeSha256(buffer) {
    return crypto.createHash('sha256').update(buffer).digest('hex');
  }

  /**
   * Generates a compact BlurHash string placeholder
   */
  static async generateBlurhash(imageBuffer) {
    try {
      const { data, info } = await sharp(imageBuffer)
        .resize(32, 32, { fit: 'inside' })
        .ensureAlpha()
        .raw()
        .toBuffer({ resolveWithObject: true });

      return encodeBlurhash(new Uint8ClampedArray(data), info.width, info.height, 4, 3);
    } catch (err) {
      console.warn('Failed to generate blurhash, using fallback', err.message);
      return 'L6PZfSi_.AyE_3t7t7R**0o#DgR4'; // neutral pleasing fallback
    }
  }

  /**
   * Main Pipeline: Process raw uploaded image from camera/gallery
   * 1. Calculate SHA-256 for deduplication
   * 2. Check if already exists in DB 1 & DB 2 (instant deduplication!)
   * 3. Strip EXIF GPS/device metadata (privacy & size reduction)
   * 4. Convert to WebP with multi-variant generation
   * 5. Save WebP binaries to DB 2 (dedicated media store)
   * 6. Save metadata to DB 1
   */
  static async processAndStoreImage(rawBuffer, userId) {
    if (!rawBuffer || rawBuffer.length === 0) {
      throw new Error('Image buffer is empty');
    }

    const sha256 = this.computeSha256(rawBuffer);

    // 1. DEDUPLICATION CHECK: Check if this identical image is already in DB 1
    const checkStmt = db1.prepare('SELECT * FROM media_assets WHERE sha256_hash = ?');
    const existing = checkStmt.get(sha256);

    if (existing) {
      // Re-use existing asset; zero new bytes in DB 2!
      return {
        id: existing.id,
        sha256: existing.sha256_hash,
        blurhash: existing.blurhash,
        width: existing.width,
        height: existing.height,
        originalSizeBytes: existing.original_size_bytes,
        compressedSizeBytes: existing.compressed_size_bytes,
        compressionRatio: existing.compression_ratio,
        savedBytes: existing.original_size_bytes - existing.compressed_size_bytes,
        isDeduplicated: true,
        urls: {
          thumb: `${config.baseUrl}/api/media/thumb/${existing.sha256_hash}`,
          feed: `${config.baseUrl}/api/media/feed/${existing.sha256_hash}`,
          full: `${config.baseUrl}/api/media/full/${existing.sha256_hash}`,
        },
      };
    }

    // 2. Read metadata and auto-orient
    const pipeline = sharp(rawBuffer).rotate(); // auto-rotate based on EXIF orientation
    const meta = await pipeline.metadata();

    // 3. Generate BlurHash
    const blurhash = await this.generateBlurhash(rawBuffer);

    // 4. Generate Optimized Variants (WebP, C-based libvips engine)
    const opts = config.imageOptimization.variants;

    // Variant A: Thumbnail 150x150
    const thumbBuffer = await sharp(rawBuffer)
      .rotate()
      .resize(opts.thumb.width, opts.thumb.height, { fit: opts.thumb.fit, position: 'center' })
      .webp({ quality: opts.thumb.quality, effort: 4 })
      .toBuffer();

    // Variant B: Feed 800x800 square (Locket-style 1:1 view)
    const feedBuffer = await sharp(rawBuffer)
      .rotate()
      .resize(opts.feed.width, opts.feed.height, { fit: opts.feed.fit, position: 'center' })
      .webp({ quality: opts.feed.quality, effort: 4 })
      .toBuffer();

    // Variant C: Full / Detail 1200px max
    const fullBuffer = await sharp(rawBuffer)
      .rotate()
      .resize(opts.full.maxWidth, opts.full.maxHeight, { fit: opts.full.fit, withoutEnlargement: true })
      .webp({ quality: opts.full.quality, effort: 4 })
      .toBuffer();

    // 5. Store binary variants in DB 2 (Dedicated Blob Storage)
    const thumbRelPath = db2Storage.saveVariant(sha256, 'thumb', thumbBuffer);
    const feedRelPath = db2Storage.saveVariant(sha256, 'feed', feedBuffer);
    const fullRelPath = db2Storage.saveVariant(sha256, 'full', fullBuffer);

    // 6. Record metadata in DB 1 (Users / Relational Database)
    const mediaId = crypto.randomUUID();
    const originalSizeBytes = rawBuffer.length;
    const compressedSizeBytes = feedBuffer.length;
    const compressionRatio = Number((compressedSizeBytes / originalSizeBytes).toFixed(4));
    const now = new Date().toISOString();

    const insertStmt = db1.prepare(`
      INSERT INTO media_assets (
        id, owner_id, sha256_hash, blurhash, width, height,
        original_size_bytes, compressed_size_bytes, compression_ratio,
        mime_type, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'image/webp', ?)
    `);

    insertStmt.run(
      mediaId,
      userId,
      sha256,
      blurhash,
      meta.width || 800,
      meta.height || 800,
      originalSizeBytes,
      compressedSizeBytes,
      compressionRatio,
      now
    );

    return {
      id: mediaId,
      sha256,
      blurhash,
      width: meta.width || 800,
      height: meta.height || 800,
      originalSizeBytes,
      compressedSizeBytes,
      compressionRatio,
      savedBytes: originalSizeBytes - compressedSizeBytes,
      percentReduction: `${((1 - compressionRatio) * 100).toFixed(1)}%`,
      isDeduplicated: false,
      paths: {
        thumb: thumbRelPath,
        feed: feedRelPath,
        full: fullRelPath,
      },
      urls: {
        thumb: `${config.baseUrl}/api/media/thumb/${sha256}`,
        feed: `${config.baseUrl}/api/media/feed/${sha256}`,
        full: `${config.baseUrl}/api/media/full/${sha256}`,
      },
    };
  }
}

