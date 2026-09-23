import fs from 'node:fs';
import { ImageOptimizationService } from '../services/image_service.js';
import { db2Storage } from '../db/db2_storage.js';
import { db1 } from '../db/db1_users.js';

export class MediaController {
  /**
   * Upload and optimize an image entirely on the backend
   */
  static async upload(req, res, next) {
    try {
      if (!req.file || !req.file.buffer) {
        return res.status(400).json({
          success: false,
          message: 'No image file uploaded (field name must be "image")',
        });
      }

      const userId = req.user ? req.user.id : 'system_guest';
      const result = await ImageOptimizationService.processAndStoreImage(req.file.buffer, userId);

      res.status(201).json({
        success: true,
        message: result.isDeduplicated
          ? 'Image already exists! Re-used existing optimized asset (0 byte storage overhead)'
          : `Image optimized successfully! Reduced by ${result.percentReduction}`,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Stream optimized WebP image with 1-year immutable caching headers
   */
  static serve(req, res, next) {
    try {
      const { variant, hash: rawHash } = req.params;
      const cleanHash = rawHash.replace(/\.webp$/i, '');

      if (!['thumb', 'feed', 'full'].includes(variant)) {
        return res.status(400).json({ success: false, message: 'Invalid variant (must be thumb, feed, or full)' });
      }

      const filePath = db2Storage.getVariantPath(cleanHash, variant);
      if (!filePath) {
        return res.status(404).json({ success: false, message: 'Image asset not found in DB 2 storage' });
      }

      const stat = fs.statSync(filePath);

      // Strong ETag based on hash and variant
      const etag = `"${cleanHash.slice(0, 16)}-${variant}"`;
      if (req.headers['if-none-match'] === etag) {
        return res.status(304).end();
      }

      res.writeHead(200, {
        'Content-Type': 'image/webp',
        'Content-Length': stat.size,
        'Cache-Control': 'public, max-age=31536000, immutable',
        'ETag': etag,
        'X-Crouket-DB': 'DB-2-Blob-Storage',
      });

      fs.createReadStream(filePath).pipe(res);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Get 2-DB metrics and storage savings
   */
  static getStorageStats(req, res, next) {
    try {
      const db1MediaCount = db1.prepare('SELECT COUNT(*) as count, SUM(original_size_bytes) as total_orig, SUM(compressed_size_bytes) as total_comp FROM media_assets').get();
      const db2Metrics = db2Storage.getStorageMetrics();

      const totalOrig = db1MediaCount.total_orig || 0;
      const totalComp = db1MediaCount.total_comp || 0;
      const totalSavedBytes = Math.max(0, totalOrig - totalComp);

      res.json({
        success: true,
        data: {
          database1_UserMetadata: {
            engine: 'SQLite WAL / PostgreSQL (DB 1)',
            totalMediaRecords: db1MediaCount.count,
            totalOriginalBytes: totalOrig,
            totalOriginalMB: (totalOrig / (1024 * 1024)).toFixed(2) + ' MB',
          },
          database2_MediaBlob: {
            ...db2Metrics,
          },
          backendSavings: {
            bytesSaved: totalSavedBytes,
            megaBytesSaved: (totalSavedBytes / (1024 * 1024)).toFixed(2) + ' MB',
            overallReduction: totalOrig > 0 ? `${(((totalOrig - totalComp) / totalOrig) * 100).toFixed(1)}%` : '0%',
          },
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

