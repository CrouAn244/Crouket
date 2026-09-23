import { Router } from 'express';
import { StatsController } from '../controllers/stats_controller.js';
import { authenticate } from '../middleware/auth_middleware.js';

const router = Router();

router.get('/', authenticate, StatsController.getStats);

export default router;

