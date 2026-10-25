import crypto from 'node:crypto';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import multer from 'multer';
import { Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../config/database.js';
import { authRequired, requireRole } from '../middleware/auth.js';
import { badRequest, forbidden, notFound } from '../utils/errors.js';
import { asyncHandler } from '../utils/async.js';
import { created, ok } from '../utils/response.js';

const router = Router();
const uploadDirectory = fileURLToPath(new URL('../../uploads/', import.meta.url));
fs.mkdirSync(uploadDirectory, { recursive: true });

const imageExtension = {
  'image/jpeg': '.jpg',
  'image/jpg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

const extensionImageType = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

function uploadedImageType(file) {
  const mimeType = file.mimetype.toLowerCase();
  if (imageExtension[mimeType]) return mimeType;
  if (mimeType === 'application/octet-stream' || !mimeType) {
    const extension = file.originalname
      .slice(file.originalname.lastIndexOf('.'))
      .toLowerCase();
    return extensionImageType[extension] ?? null;
  }
  return null;
}

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, callback) =>
      callback(null, uploadDirectory),
    filename: (_req, file, callback) =>
      callback(
        null,
        `${crypto.randomUUID()}${imageExtension[uploadedImageType(file)]}`,
      ),
  }),
  limits: { fileSize: 8 * 1024 * 1024, files: 8 },
  fileFilter: (_req, file, callback) => {
    if (!uploadedImageType(file)) {
      callback(badRequest('Upload JPEG, PNG, or WebP photos only.'));
      return;
    }
    callback(null, true);
  },
});

const receiveHotelPhotos = (req, res, next) => {
  upload.array('images', 8)(req, res, (error) => {
    if (!error) return next();
    if (error.code === 'LIMIT_FILE_SIZE') {
      return next(badRequest('Each hotel photo must be 8 MB or smaller.'));
    }
    if (error instanceof multer.MulterError) {
      return next(badRequest(error.message));
    }
    return next(error);
  });
};

const galleryJson = `COALESCE((
  SELECT json_agg(json_build_object('url', i.url, 'isCover', i.is_cover)
                  ORDER BY i.sort_order)
  FROM hotel_images i WHERE i.hotel_id = h.id
), '[]'::json)`;

const amenitiesJson = `COALESCE((
  SELECT json_agg(json_build_object('amenity', json_build_object('name', amenity)))
  FROM unnest(h.amenities) AS amenity
), '[]'::json)`;

const hotelColumns = `
  h.id::text AS id,
  h.name,
  h.city,
  h.address,
  h.description,
  h.category::text AS category,
  h.base_price AS "basePrice",
  h.status::text AS status,
  h.rooms_available AS "roomsAvailable",
  h.other_details AS "otherDetails",
  h.cover_image AS "coverImage",
  0::float8 AS rating,
  ${galleryJson} AS images,
  ${amenitiesJson} AS amenities,
  json_build_array(json_build_object(
    'id', h.id::text,
    'name', 'Standard room',
    'pricePerNight', h.base_price,
    'totalRooms', h.rooms_available
  )) AS "roomTypes"
`;

const categoryMap = new Map([
  ['luxury', 'luxury'],
  ['medium-range', 'budget'],
  ['other', 'guesthouse'],
  ['budget', 'budget'],
  ['resort', 'resort'],
  ['guesthouse', 'guesthouse'],
]);

const inputSchema = z.object({
  name: z.string().trim().min(2).max(150),
  city: z.string().trim().min(2).max(100),
  address: z.string().trim().min(3).max(255),
  description: z.string().trim().min(10),
  category: z.string().transform((value) => value.toLowerCase())
    .refine((value) => categoryMap.has(value), 'Choose a supported hotel category'),
  basePrice: z.coerce.number().int().positive(),
  roomsAvailable: z.coerce.number().int().positive().max(10000).optional(),
  amenities: z.union([z.string(), z.array(z.string())]).optional().default(''),
  otherDetails: z.string().trim().max(4000).optional().default(''),
  phone: z.string().trim().max(30).optional(),
  email: z.string().trim().email().optional(),
  images: z.array(z.string().url()).optional(),
});

function parseAmenities(value) {
  const names = Array.isArray(value) ? value : value.split(',');
  return [...new Set(names.map((name) => name.trim()).filter(Boolean))].slice(0, 30);
}

function imageUrl(req, filename) {
  return `${req.protocol}://${req.get('host')}/uploads/${filename}`;
}

function queryDate(value) {
  const match = typeof value === 'string'
    ? /^(\d{4}-\d{2}-\d{2})/.exec(value)
    : null;
  if (!match) return null;
  const date = new Date(`${match[1]}T00:00:00.000Z`);
  if (
    Number.isNaN(date.getTime()) ||
    date.toISOString().slice(0, 10) !== match[1]
  ) {
    return null;
  }
  return match[1];
}

function formatHotel(req, hotel) {
  const images = (hotel.images ?? []).map((image) => ({
    ...image,
    url: image.url.startsWith('/uploads/')
      ? imageUrl(req, image.url.substring('/uploads/'.length))
      : image.url,
  }));
  return {
    ...hotel,
    coverImage: hotel.coverImage?.startsWith('/uploads/')
      ? imageUrl(req, hotel.coverImage.substring('/uploads/'.length))
      : hotel.coverImage,
    images,
  };
}

function parseForm(body) {
  const parsed = inputSchema.safeParse({
    ...body,
    category: body.category,
  });
  if (!parsed.success) {
    throw badRequest(parsed.error.issues.map((issue) => issue.message).join(' '));
  }
  return {
    ...parsed.data,
    category: categoryMap.get(parsed.data.category),
    roomsAvailable: parsed.data.roomsAvailable ?? 1,
    amenities: parseAmenities(parsed.data.amenities),
  };
}

async function addImages(tx, hotelId, files, remoteImages = []) {
  const imageUrls = [
    ...files.map((file) => `/uploads/${file.filename}`),
    ...remoteImages,
  ];
  for (let index = 0; index < imageUrls.length; index++) {
    const url = imageUrls[index];
    await tx.$executeRaw`
      INSERT INTO hotel_images (hotel_id, url, sort_order, is_cover)
      VALUES (${hotelId}::uuid, ${url}, ${index}, ${index === 0})
    `;
  }
}

router.get(
  '/mine',
  authRequired,
  requireRole('OWNER'),
  asyncHandler(async (req, res) => {
    const hotels = await prisma.$queryRaw`
      SELECT ${Prisma.raw(hotelColumns)}
      FROM hotels h
      WHERE h.owner_id = ${req.user.id}::uuid
      ORDER BY h.created_at DESC
    `;
    ok(res, hotels.map((hotel) => formatHotel(req, hotel)));
  }),
);

router.get(
  '/',
  asyncHandler(async (req, res) => {
    const city = typeof req.query.city === 'string' ? req.query.city.trim() : '';
    const category = typeof req.query.category === 'string'
      ? categoryMap.get(req.query.category.toLowerCase()) ?? req.query.category
      : null;
    const minPrice = Number(req.query.minPrice) || 0;
    const maxPrice = Number(req.query.maxPrice) || 2_147_483_647;
    const hotels = await prisma.$queryRaw`
      SELECT ${Prisma.raw(hotelColumns)}
      FROM hotels h
      WHERE h.status = 'APPROVED'
        AND (
          h.owner_id IS NULL OR EXISTS (
            SELECT 1 FROM users owner_account
            WHERE owner_account.id = h.owner_id
              AND owner_account.is_active = TRUE
          )
        )
        AND h.base_price BETWEEN ${minPrice} AND ${maxPrice}
        AND (${city} = '' OR h.city ILIKE '%' || ${city} || '%')
        AND (${category}::text IS NULL OR h.category::text = ${category})
      ORDER BY h.created_at DESC
      LIMIT 100
    `;
    ok(res, hotels.map((hotel) => formatHotel(req, hotel)));
  }),
);

router.post(
  '/',
  authRequired,
  requireRole('OWNER', 'ADMIN'),
  receiveHotelPhotos,
  asyncHandler(async (req, res) => {
    const data = parseForm(req.body);
    if (req.user.role === 'OWNER' && req.body.roomsAvailable == null) {
      throw badRequest('Enter the number of available rooms.');
    }
    if (
      req.user.role === 'OWNER' &&
      !req.files?.length &&
      !data.images?.length
    ) {
      throw badRequest('Add at least one hotel photo.');
    }

    const hotel = await prisma.$transaction(async (tx) => {
      const [createdHotel] = await tx.$queryRaw`
        INSERT INTO hotels (
          owner_id, name, city, address, description, category, base_price,
          phone, email, status, rooms_available, amenities, other_details
        ) VALUES (
          ${req.user.id}::uuid, ${data.name}, ${data.city}, ${data.address},
          ${data.description}, CAST(${data.category} AS hotel_category),
          ${data.basePrice}, ${data.phone ?? req.user.phone ?? null},
          ${data.email ?? req.user.email}, 'APPROVED',
          ${data.roomsAvailable}, ${data.amenities}::text[], ${data.otherDetails}
        )
        RETURNING id::text AS id
      `;
      await addImages(tx, createdHotel.id, req.files ?? [], data.images ?? []);
      if (req.user.role === 'OWNER') {
        await tx.$executeRaw`
          INSERT INTO user_notifications (user_id, hotel_id, title, message)
          SELECT traveler.id, ${createdHotel.id}::uuid,
            ${`${data.name} is now on GUZO`},
            ${`A new stay in ${data.city} has been posted. View its photos, price, and details.`}
          FROM users traveler
          WHERE traveler.role::text = 'TRAVELER'
            AND traveler.is_active = TRUE
        `;
      }
      const [result] = await tx.$queryRaw`
        SELECT ${Prisma.raw(hotelColumns)}
        FROM hotels h WHERE h.id = ${createdHotel.id}::uuid
      `;
      return result;
    });

    created(res, formatHotel(req, hotel));
  }),
);

router.get(
  '/:id/availability',
  asyncHandler(async (req, res) => {
    const checkIn = queryDate(req.query.checkIn);
    const checkOut = queryDate(req.query.checkOut);
    if (!checkIn || !checkOut || checkOut <= checkIn) {
      throw badRequest('A valid check-in and check-out date range is required.');
    }

    const [availability] = await prisma.$queryRaw`
      SELECT h.id::text AS "hotelId",
        h.rooms_available AS "totalRooms",
        h.base_price AS "pricePerNight",
        GREATEST(
          0,
          h.rooms_available - COALESCE((
            SELECT COUNT(*)::int
            FROM hotel_bookings b
            WHERE b.hotel_id = h.id
              AND b.status IN ('PENDING', 'CONFIRMED')
              AND b.check_in < ${checkOut}::date
              AND b.check_out > ${checkIn}::date
          ), 0)
        ) AS "availableRooms",
        (${checkOut}::date - ${checkIn}::date) AS nights
      FROM hotels h
      WHERE h.id = ${req.params.id}::uuid
        AND h.status = 'APPROVED'
        AND (
          h.owner_id IS NULL OR EXISTS (
            SELECT 1 FROM users owner_account
            WHERE owner_account.id = h.owner_id
              AND owner_account.is_active = TRUE
          )
        )
    `;
    if (!availability) throw notFound('Hotel not found');
    if (availability.nights < 1) {
      throw badRequest('Check-out must be at least one night after check-in.');
    }

    ok(res, {
      hotelId: availability.hotelId,
      availableRooms: availability.availableRooms,
      nights: availability.nights,
      pricePerNight: availability.pricePerNight,
      totalPrice: availability.pricePerNight * availability.nights,
    });
  }),
);

router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const [hotel] = await prisma.$queryRaw`
      SELECT ${Prisma.raw(hotelColumns)}
      FROM hotels h
      WHERE h.id = ${req.params.id}::uuid AND h.status = 'APPROVED'
        AND (
          h.owner_id IS NULL OR EXISTS (
            SELECT 1 FROM users owner_account
            WHERE owner_account.id = h.owner_id
              AND owner_account.is_active = TRUE
          )
        )
    `;
    if (!hotel) throw notFound('Hotel not found');
    ok(res, formatHotel(req, hotel));
  }),
);

router.patch(
  '/:id',
  authRequired,
  requireRole('OWNER'),
  receiveHotelPhotos,
  asyncHandler(async (req, res) => {
    const data = parseForm(req.body);
    const [existing] = await prisma.$queryRaw`
      SELECT owner_id::text AS "ownerId" FROM hotels WHERE id = ${req.params.id}::uuid
    `;
    if (!existing) throw notFound('Hotel not found');
    if (existing.ownerId !== req.user.id) throw forbidden('You can only edit your own hotel posts.');

    const hotel = await prisma.$transaction(async (tx) => {
      await tx.$executeRaw`
        UPDATE hotels SET
          name = ${data.name},
          city = ${data.city},
          address = ${data.address},
          description = ${data.description},
          category = CAST(${data.category} AS hotel_category),
          base_price = ${data.basePrice},
          rooms_available = ${data.roomsAvailable},
          amenities = ${data.amenities}::text[],
          other_details = ${data.otherDetails},
          updated_at = NOW()
        WHERE id = ${req.params.id}::uuid AND owner_id = ${req.user.id}::uuid
      `;
      if (req.files?.length) {
        await tx.$executeRaw`DELETE FROM hotel_images WHERE hotel_id = ${req.params.id}::uuid`;
        await addImages(tx, req.params.id, req.files);
      }
      const [result] = await tx.$queryRaw`
        SELECT ${Prisma.raw(hotelColumns)}
        FROM hotels h WHERE h.id = ${req.params.id}::uuid
      `;
      return result;
    });
    ok(res, formatHotel(req, hotel));
  }),
);

router.delete(
  '/:id',
  authRequired,
  requireRole('OWNER'),
  asyncHandler(async (req, res) => {
    const [existing] = await prisma.$queryRaw`
      SELECT owner_id::text AS "ownerId" FROM hotels WHERE id = ${req.params.id}::uuid
    `;
    if (!existing) throw notFound('Hotel not found');
    if (existing.ownerId !== req.user.id) throw forbidden('You can only delete your own hotel posts.');
    await prisma.$executeRaw`
      DELETE FROM hotels WHERE id = ${req.params.id}::uuid AND owner_id = ${req.user.id}::uuid
    `;
    ok(res, { deleted: true });
  }),
);

export default router;
