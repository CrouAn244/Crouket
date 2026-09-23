import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

export const config = {
  port: process.env.PORT ? parseInt(process.env.PORT, 10) : 3000,
  jwtSecret: process.env.JWT_SECRET || 'crouket-super-secret-key-change-in-production-2026',
  jwtExpiresIn: '30d',
  baseUrl: process.env.BASE_URL || 'http://localhost:3000',
  
  // DB 1: Relational Metadata Database (SQLite WAL / PostgreSQL)
  db1Path: process.env.DB1_PATH || path.join(rootDir, 'data', 'crouket_users.db'),
  
  // DB 2: Dedicated Content-Addressable Binary Media Storage
  db2StorageDir: process.env.DB2_STORAGE_DIR || path.join(rootDir, 'storage', 'media'),

  // Image optimization parameters (Handled by Backend)
  imageOptimization: {
    maxUploadSizeBytes: 20 * 1024 * 1024, // 20 MB max raw upload
    stripExif: true,
    variants: {
      thumb: {
        width: 150,
        height: 150,
        quality: 75,
        fit: 'cover',
      },
      feed: {
        width: 800,
        height: 800,
        quality: 82,
        fit: 'cover',
      },
      full: {
        maxWidth: 1200,
        maxHeight: 1200,
        quality: 85,
        fit: 'inside',
      },
    },
  },
};

