import { Router } from 'express';
import { FriendController } from '../controllers/friend_controller.js';
import { authenticate } from '../middleware/auth_middleware.js';

const router = Router();

router.get('/', authenticate, FriendController.list);
router.post('/add', authenticate, FriendController.addByCrouketId);

export default router;

