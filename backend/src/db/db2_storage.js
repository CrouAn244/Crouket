import fs from 'node:fs';
import path from 'node:path';
import { config } from '../config.js';

class Db2StorageEngine {
  constructor(baseDir = config.db2StorageDir) {
    this.baseDir = baseDir;
    this.variants = ['thumb', 'feed', 'full'];
    this._ensureDirectories();
  }

  _ensureDirectories() {
    if (!fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
    for (const variant of this.variants) {
      const vDir = path.join(this.baseDir, variant);
      if (!fs.existsSync(vDir)) {
        fs.mkdirSync(vDir, { recursive: true });
      }
    }
  }

  /**
   * Generates a sharded relative path to avoid millions of files in one directory:
   * e.g., variant/ab/cd/abcdef123456...webp
   */
  _getRelativePath(hash, variant) {
    const shard1 = hash.slice(0, 2);
    const shard2 = hash.slice(2, 4);
    return path.join(variant, shard1, shard2, `${hash}.webp`);
  }

  _getAbsolutePath(hash, variant) {
    return path.join(this.baseDir, this._getRelativePath(hash, variant));
  }

  /**
   * Check if a variant already exists in DB 2 (Content-Addressed deduplication)
   */
  hasVariant(hash, variant) {
    const fullPath = this._getAbsolutePath(hash, variant);
    return fs.existsSync(fullPath);
  }

  /**
   * Save an optimized WebP binary buffer into DB 2
   */
  saveVariant(hash, variant, buffer) {
    const fullPath = this._getAbsolutePath(hash, variant);
    const parentDir = path.dirname(fullPath);
    if (!fs.existsSync(parentDir)) {
      fs.mkdirSync(parentDir, { recursive: true });
    }
    // Atomic write to prevent partial reads
    const tempPath = `${fullPath}.${Date.now()}.tmp`;
    fs.writeFileSync(tempPath, buffer);
    fs.renameSync(tempPath, fullPath);
    return this._getRelativePath(hash, variant).replace(/\\/g, '/');
  }

  /**
   * Get the absolute path of a stored WebP variant for streaming
   */
  getVariantPath(hash, variant) {
    const fullPath = this._getAbsolutePath(hash, variant);
    if (fs.existsSync(fullPath)) {
      return fullPath;
    }
    return null;
  }

  /**
   * Return storage metrics (calculating deduplication and compression savings)
   */
  getStorageMetrics() {
    let totalFiles = 0;
    let totalBytesStored = 0;

    const traverse = (dir) => {
      if (!fs.existsSync(dir)) return;
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          traverse(full);
        } else if (entry.isFile() && entry.name.endsWith('.webp')) {
          totalFiles++;
          totalBytesStored += fs.statSync(full).size;
        }
      }
    };

    traverse(this.baseDir);

    return {
      storageEngine: 'Dedicated Content-Addressable Blob DB (DB 2)',
      totalStoredVariants: totalFiles,
      totalBytesStored,
      totalMegaBytesStored: (totalBytesStored / (1024 * 1024)).toFixed(2) + ' MB',
      location: this.baseDir,
    };
  }
}

export const db2Storage = new Db2StorageEngine();

