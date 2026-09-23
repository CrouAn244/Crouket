import { Router } from 'express';
import { TransactionController } from '../controllers/transaction_controller.js';
import { authenticate } from '../middleware/auth_middleware.js';
import { AuthService } from '../services/auth_service.js';

const router = Router();

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

// Feed is viewable by all (or tailored if logged in)
router.get('/feed', optionalAuth, TransactionController.getFeed);

// Create transaction requires authentication
router.post('/', authenticate, TransactionController.create);

// Toggle reaction requires authentication
router.post('/:id/react', authenticate, TransactionController.toggleReaction);

export default router;

