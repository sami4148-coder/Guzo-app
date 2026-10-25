import { Router } from 'express';
import { prisma } from '../config/database.js';
import { authRequired, requireRole } from '../middleware/auth.js';
import { asyncHandler } from '../utils/async.js';
import { notFound } from '../utils/errors.js';
import { ok } from '../utils/response.js';

const router = Router();

router.use(authRequired, requireRole('TRAVELER'));

router.get(
  '/',
  asyncHandler(async (req, res) => {
    const notifications = await prisma.$queryRaw`
      SELECT n.id::text AS id,
        n.hotel_id::text AS "hotelId",
        n.title,
        n.message,
        n.created_at AS "createdAt",
        n.read_at AS "readAt",
        (
          SELECT image.url
          FROM hotel_images image
          WHERE image.hotel_id = n.hotel_id
          ORDER BY image.sort_order
          LIMIT 1
        ) AS "imageUrl"
      FROM user_notifications n
      WHERE n.user_id = ${req.user.id}::uuid
      ORDER BY n.created_at DESC
      LIMIT 100
    `;
    ok(res, notifications.map((notification) => ({
      ...notification,
      imageUrl: notification.imageUrl?.startsWith('/uploads/')
        ? `${req.protocol}://${req.get('host')}${notification.imageUrl}`
        : notification.imageUrl,
    })));
  }),
);

router.patch(
  '/:id/read',
  asyncHandler(async (req, res) => {
    const [notification] = await prisma.$queryRaw`
      UPDATE user_notifications
      SET read_at = COALESCE(read_at, NOW())
      WHERE id = ${req.params.id}::uuid
        AND user_id = ${req.user.id}::uuid
      RETURNING id::text AS id, read_at AS "readAt"
    `;
    if (!notification) throw notFound('Notification not found');
    ok(res, notification);
  }),
);

export default router;
