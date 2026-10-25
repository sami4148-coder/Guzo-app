import { z } from 'zod';
import { prisma } from '../config/database.js';
import { asyncHandler } from '../utils/async.js';
import { ok, created } from '../utils/response.js';
import { badRequest, forbidden, notFound } from '../utils/errors.js';

export const hotelCreateSchema = z.object({
  name: z.string().min(2),
  city: z.string().min(2),
  address: z.string().min(3),
  description: z.string().min(10),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  category: z.enum(['luxury', 'budget', 'resort', 'guesthouse']),
  basePrice: z.number().int().positive(),
  images: z.array(z.string().url()).optional(),
  amenities: z.array(z.string()).optional(),
});

export const hotelUpdateSchema = hotelCreateSchema.partial();

// GET /api/hotels
export const listHotels = asyncHandler(async (req, res) => {
  const {
    city, category, minPrice, maxPrice, minRating,
    guests, amenities, sort = 'popularity',
    page = '1', limit = '12',
  } = req.query;

  const where = { status: 'APPROVED' };
  if (city) where.city = { contains: city, mode: 'insensitive' };
  if (category) where.category = category;
  if (minPrice || maxPrice) {
    where.basePrice = {};
    if (minPrice) where.basePrice.gte = parseInt(minPrice, 10);
    if (maxPrice) where.basePrice.lte = parseInt(maxPrice, 10);
  }
  if (minRating) where.rating = { gte: parseFloat(minRating) };
  if (guests) where.roomTypes = { some: { maxGuests: { gte: parseInt(guests, 10) } } };
  if (amenities) {
    const list = Array.isArray(amenities) ? amenities : amenities.split(',');
    where.amenities = { some: { amenity: { name: { in: list } } } };
  }

  const orderBy =
    sort === 'price_asc' ? { basePrice: 'asc' } :
    sort === 'price_desc' ? { basePrice: 'desc' } :
    sort === 'rating' ? { rating: 'desc' } :
    { createdAt: 'desc' };

  const pageNum = Math.max(1, parseInt(page, 10));
  const pageSize = Math.min(50, Math.max(1, parseInt(limit, 10)));

  const [items, total] = await Promise.all([
    prisma.hotel.findMany({
      where,
      orderBy,
      skip: (pageNum - 1) * pageSize,
      take: pageSize,
      include: {
        images: { take: 1, orderBy: { isCover: 'desc' } },
        roomTypes: { select: { id: true, maxGuests: true, pricePerNight: true } },
        amenities: { include: { amenity: true } },
      },
    }),
    prisma.hotel.count({ where }),
  ]);

  ok(res, items, { page: pageNum, pageSize, total, totalPages: Math.ceil(total / pageSize) });
});

// GET /api/hotels/:id
export const getHotel = asyncHandler(async (req, res) => {
  const hotel = await prisma.hotel.findUnique({
    where: { id: req.params.id },
    include: {
      images: true,
      roomTypes: true,
      amenities: { include: { amenity: true } },
      owner: { select: { id: true, fullName: true, email: true } },
    },
  });
  if (!hotel) throw notFound('Hotel not found');
  ok(res, hotel);
});

// POST /api/hotels (OWNER only)
export const createHotel = asyncHandler(async (req, res) => {
  const data = req.body;
  const { images, amenities, ...rest } = data;

  const hotel = await prisma.hotel.create({
    data: {
      ...rest,
      ownerId: req.user.id,
      status: req.user.role === 'ADMIN' ? 'APPROVED' : 'PENDING',
      images: images ? { create: images.map((url, i) => ({ url, isCover: i === 0 })) } : undefined,
      amenities: amenities
        ? {
            create: await Promise.all(
              amenities.map(async (name) => {
                const amenity = await prisma.amenity.upsert({
                  where: { name },
                  create: { name },
                  update: {},
                });
                return { amenityId: amenity.id };
              })
            ),
          }
        : undefined,
    },
    include: { images: true, roomTypes: true },
  });
  created(res, hotel);
});

// PATCH /api/hotels/:id
export const updateHotel = asyncHandler(async (req, res) => {
  const hotel = await prisma.hotel.findUnique({ where: { id: req.params.id } });
  if (!hotel) throw notFound('Hotel not found');
  if (req.user.role !== 'ADMIN' && hotel.ownerId !== req.user.id) {
    throw forbidden('Not your hotel');
  }
  const { images, amenities, ...rest } = req.body;
  const updated = await prisma.hotel.update({
    where: { id: hotel.id },
    data: rest,
  });
  ok(res, updated);
});

// DELETE /api/hotels/:id
export const deleteHotel = asyncHandler(async (req, res) => {
  const hotel = await prisma.hotel.findUnique({ where: { id: req.params.id } });
  if (!hotel) throw notFound('Hotel not found');
  if (req.user.role !== 'ADMIN' && hotel.ownerId !== req.user.id) {
    throw forbidden('Not your hotel');
  }
  await prisma.hotel.delete({ where: { id: hotel.id } });
  ok(res, { deleted: true });
});

// GET /api/hotels/:id/rooms
export const listRooms = asyncHandler(async (req, res) => {
  const rooms = await prisma.roomType.findMany({
    where: { hotelId: req.params.id },
  });
  ok(res, rooms);
});

// POST /api/hotels/:id/rooms
export const roomCreateSchema = z.object({
  name: z.string().min(2),
  description: z.string().optional(),
  maxGuests: z.number().int().positive(),
  pricePerNight: z.number().int().positive(),
  totalRooms: z.number().int().positive().default(1),
});

export const createRoom = asyncHandler(async (req, res) => {
  const hotel = await prisma.hotel.findUnique({ where: { id: req.params.id } });
  if (!hotel) throw notFound('Hotel not found');
  if (req.user.role !== 'ADMIN' && hotel.ownerId !== req.user.id) {
    throw forbidden('Not your hotel');
  }
  const room = await prisma.roomType.create({
    data: { ...req.body, hotelId: hotel.id },
  });
  created(res, room);
});