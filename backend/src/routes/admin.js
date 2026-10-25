import express from 'express';
import { prisma } from '../config/database.js';
import { authRequired, requireRole } from '../middleware/auth.js';

const router = express.Router();
router.use(authRequired, requireRole('ADMIN'));

router.get('/users', async (_req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        hotelName: true,
        businessAddress: true,
        role: true,
        isActive: true,
        ownerStatus: true,
        createdAt: true,
      },
    });
    res.json(users.map((user) => ({
      id: user.id,
      email: user.email,
      full_name: user.fullName,
      phone: user.phone,
      hotel_name: user.hotelName,
      business_address: user.businessAddress,
      role: user.role,
      is_active: user.isActive,
      owner_status: user.ownerStatus,
      created_at: user.createdAt,
    })));
  } catch (err) {
    next(err);
  }
});

router.patch('/users/:id/approve', async (req, res, next) => {
  try {
    const result = await prisma.user.updateMany({
      where: { id: req.params.id, role: 'OWNER' },
      data: { isActive: true, ownerStatus: 'APPROVED' },
    });
    if (result.count === 0) {
      return res.status(404).json({
        success: false,
        error: { message: 'Hotel owner not found', code: 'NOT_FOUND' },
      });
    }
    res.json({ success: true, data: { approved: true } });
  } catch (err) {
    next(err);
  }
});

router.patch('/users/:id/ban', async (req, res, next) => {
  try {
    const result = await prisma.user.updateMany({
      where: { id: req.params.id, role: 'OWNER' },
      data: { isActive: false, ownerStatus: 'BANNED' },
    });
    if (result.count === 0) {
      return res.status(404).json({
        success: false,
        error: { message: 'Hotel owner not found', code: 'NOT_FOUND' },
      });
    }
    res.json({ success: true, data: { banned: true } });
  } catch (err) {
    next(err);
  }
});

// GET STATS
router.get('/stats', async (req, res, next) => {
  try {
    const stats = await prisma.$queryRaw`SELECT * FROM fn_admin_stats()`;
    res.json(stats[0]);
  } catch (err) {
    next(err);
  }
});

// GET HOTELS
router.get('/hotels', async (req, res, next) => {
  try {
    // Call the View we created in PostgreSQL
    const hotels = await prisma.$queryRaw`SELECT * FROM v_hotels_admin ORDER BY created_at DESC`;
    res.json(hotels);
  } catch (err) {
    next(err);
  }
});

// ADD HOTEL
router.post('/hotels', async (req, res, next) => {
  try {
    const { name, city, address, description, category, basePrice, phone, email, images, amenities } = req.body;
    
    // Call the function we created
    const result = await prisma.$queryRaw`
      SELECT fn_add_hotel(
        ${name}, ${city}, ${address}, ${description}, ${category}, 
        ${Number(basePrice)}, ${phone || null}, ${email || null},
        ${images || []}, ${amenities || []}, null
      ) as id
    `;
    
    res.status(201).json({ success: true, id: result[0].id });
  } catch (err) {
    next(err);
  }
});

// APPROVE / SUSPEND HOTEL
router.patch('/hotels/:id/:action', async (req, res, next) => {
  try {
    const { id, action } = req.params;
    
    await prisma.$queryRaw`
      SELECT fn_moderate_hotel(${id}::uuid, ${action}, null)
    `;
    
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;