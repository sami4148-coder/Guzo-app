import { Router } from 'express';
import {
  login,
  loginSchema,
  me,
  register,
  registerSchema,
  updateProfile,
  updateProfileSchema,
} from '../controllers/authController.js';
import { authRequired } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';

const router = Router();

router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);
router.get('/me', authRequired, me);
router.patch('/me', authRequired, validate(updateProfileSchema), updateProfile);

export default router;
