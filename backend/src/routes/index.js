import { Router } from 'express';
import authRoutes from './auth.js';
import adminRoutes from './admin.js';
import hotelRoutes from './hotels.js';
import bookingRoutes, { ownerBookingRoutes } from './bookings.js';
import notificationRoutes from './notifications.js';

const router = Router();

// Mount the routes
router.use('/auth', authRoutes);
router.use('/admin', adminRoutes);
router.use('/hotels', hotelRoutes);
router.use('/bookings', bookingRoutes);
router.use('/owner/bookings', ownerBookingRoutes);
router.use('/notifications', notificationRoutes);

export default router;