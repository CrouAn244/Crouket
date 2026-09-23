import { Router } from 'express';
import { MediaController } from '../controllers/media_controller.js';
import { uploadSingleImage } from '../middleware/upload_middleware.js';
import { AuthService } from '../services/auth_service.js';

const router = Router();

// Optional auth helper for upload so guests can test or logged in users link to their account
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    const decoded = AuthService.verifyToken(token);
    if (decoded) {
      req.user = decoded;
    }
  }
  next();
}

// Upload & optimize image directly via Backend pipeline
router.post('/upload', optionalAuth, uploadSingleImage, MediaController.upload);

// Storage metrics comparing DB 1 vs DB 2
router.get('/stats', MediaController.getStorageStats);

// Stream optimized WebP image variants
router.get('/:variant/:hash', MediaController.serve);

export default router;

