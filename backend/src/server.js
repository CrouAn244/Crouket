import express from 'express';
import cors from 'cors';
import { config } from './config.js';
import { initDb1Schema } from './db/db1_users.js';
import { runSeed } from './db/seed.js';

// Import Routes
import authRoutes from './routes/auth_routes.js';
import mediaRoutes from './routes/media_routes.js';
import transactionRoutes from './routes/transaction_routes.js';
import statsRoutes from './routes/stats_routes.js';
import categoryRoutes from './routes/category_routes.js';
import friendRoutes from './routes/friend_routes.js';
import { errorHandler } from './middleware/error_middleware.js';

const app = express();

// Global Middleware
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

// Health Check & Root Info
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Crouket Locket Expense Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    architecture: {
      db1: 'SQLite WAL (User Data & Relational Metadata)',
      db2: 'Dedicated Content-Addressable Blob Storage (WebP Media)',
      imageOptimization: 'Sharp (C++ libvips) + BlurHash + Deduplication',
    },
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/media', mediaRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/friends', friendRoutes);

// Error Middleware
app.use(errorHandler);

// Initialize DBs and start server
export function startServer(port = config.port) {
  initDb1Schema();
  runSeed();

  const server = app.listen(port, () => {
    console.log(`\n🚀 Crouket Backend running on: http://localhost:${port}`);
    console.log(`📦 DB 1 (Metadata): ${config.db1Path}`);
    console.log(`🖼️  DB 2 (Media Storage): ${config.db2StorageDir}`);
    console.log(`⚡ Image Engine: Sharp (WebP, Multi-variant, BlurHash, Deduplication)\n`);
  });

  return server;
}

// Auto-start if run directly
if (process.argv[1]?.endsWith('server.js')) {
  startServer();
}

export default app;

