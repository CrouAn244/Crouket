import { Router } from 'express';
import { CategoryController } from '../controllers/category_controller.js';
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

router.get('/', optionalAuth, CategoryController.list);
router.post('/', authenticate, CategoryController.create);

export default router;

