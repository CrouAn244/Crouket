import { Router } from 'express';
import { AuthController } from '../controllers/auth_controller.js';
import { authenticate } from '../middleware/auth_middleware.js';

const router = Router();

router.post('/register', AuthController.register);
router.post('/login', AuthController.login);
router.post('/forgot-password', AuthController.forgotPassword);
router.get('/me', authenticate, AuthController.me);

export default router;

