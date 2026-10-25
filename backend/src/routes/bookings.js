import { Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../config/database.js';
import { authRequired, requireRole } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { asyncHandler } from '../utils/async.js';
import { badRequest, conflict, notFound } from '../utils/errors.js';
import { generateBookingReference } from '../utils/reference.js';
import { created, ok } from '../utils/response.js';

const router = Router();

const createBookingSchema = z.object({
  hotelId: z.string().uuid(),
  checkIn: z.string().min(1),
  checkOut: z.string().min(1),
  guests: z.number().int().positive(),
  guestName: z.string().trim().min(2).max(120),
  phone: z.string()
    .trim()
    .min(7)
    .max(30)
    .regex(/^[+()\d\s.-]+$/, 'Enter a valid phone number.'),
});

function bookingDate(value) {
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(value);
  if (!match) throw badRequest('Invalid booking dates.');
  const date = new Date(Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
  ));
  if (date.toISOString().slice(0, 10) !== match[0]) {
    throw badRequest('Invalid booking dates.');
  }
  return date;
}

function bookingDates(checkInValue, checkOutValue) {
  const checkIn = bookingDate(checkInValue);
  const checkOut = bookingDate(checkOutValue);
  const nights = (checkOut - checkIn) / 86400000;
  if (nights < 1) throw badRequest('Check-out must be at least one night after check-in.');

  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  if (checkIn < today) {
    throw badRequest('Check-in cannot be in the past.');
  }

  return { checkIn, checkOut, nights };
}

router.post(
  '/',
  authRequired,
  requireRole('TRAVELER'),
  validate(createBookingSchema),
  asyncHandler(async (req, res) => {
    const { hotelId, guests, guestName, phone } = req.body;
    const { checkIn, checkOut, nights } = bookingDates(
      req.body.checkIn,
      req.body.checkOut,
    );
    const reference = generateBookingReference();

    const [booking] = await prisma.$transaction(async (tx) => {
      const [hotel] = await tx.$queryRaw`
        SELECT h.id::text AS id,
          h.name,
          h.base_price AS "basePrice",
          h.rooms_available AS "roomsAvailable",
          h.owner_id AS "ownerId"
        FROM hotels h
        WHERE h.id = ${hotelId}::uuid
          AND h.status = 'APPROVED'
          AND (
            h.owner_id IS NULL OR EXISTS (
              SELECT 1 FROM users owner_account
              WHERE owner_account.id = h.owner_id
                AND owner_account.is_active = TRUE
            )
          )
        FOR UPDATE
      `;
      if (!hotel) throw notFound('Hotel not found or unavailable for booking.');

      const [availability] = await tx.$queryRaw`
        SELECT COUNT(*)::int AS booked
        FROM hotel_bookings b
        WHERE b.hotel_id = ${hotelId}::uuid
          AND b.status IN ('PENDING', 'CONFIRMED')
          AND b.check_in < ${checkOut}::date
          AND b.check_out > ${checkIn}::date
      `;
      if (availability.booked >= hotel.roomsAvailable) {
        throw conflict('No rooms are available for these dates.', 'ROOM_UNAVAILABLE');
      }

      const [createdBooking] = await tx.$queryRaw`
        INSERT INTO hotel_bookings (
          id, reference, user_id, hotel_id, check_in, check_out,
          guests, nights, total_price, status, guest_name, guest_phone
        ) VALUES (
          gen_random_uuid(),
          ${reference},
          ${req.user.id}::uuid,
          ${hotelId}::uuid,
          ${checkIn}::date,
          ${checkOut}::date,
          ${guests},
          ${nights},
          ${hotel.basePrice * nights},
          'PENDING',
          ${guestName},
          ${phone}
        )
        RETURNING id::text AS id, reference, check_in::text AS "checkIn",
          check_out::text AS "checkOut", guests, nights,
          total_price::float8 AS "totalPrice", status, created_at AS "createdAt"
      `;
      const [details] = await tx.$queryRaw`
        SELECT ${Prisma.raw(PrismaRawBookingSelect)}
        FROM hotel_bookings b
        JOIN hotels h ON h.id = b.hotel_id
        JOIN users guest ON guest.id = b.user_id
        WHERE b.id = ${createdBooking.id}::uuid
      `;
      return [details];
    });

    created(res, booking);
  }),
);

router.get(
  '/my',
  authRequired,
  requireRole('TRAVELER'),
  asyncHandler(async (req, res) => {
    const bookings = await prisma.$queryRaw`
      SELECT ${Prisma.raw(PrismaRawBookingSelect)}
      FROM hotel_bookings b
      JOIN hotels h ON h.id = b.hotel_id
      JOIN users guest ON guest.id = b.user_id
      WHERE b.user_id = ${req.user.id}::uuid
      ORDER BY b.created_at DESC
    `;
    ok(res, bookings);
  }),
);

export const ownerBookingRoutes = Router();

ownerBookingRoutes.get(
  '/',
  authRequired,
  requireRole('OWNER'),
  asyncHandler(async (req, res) => {
    const bookings = await prisma.$queryRaw`
      SELECT ${Prisma.raw(PrismaRawBookingSelect)}
      FROM hotel_bookings b
      JOIN hotels h ON h.id = b.hotel_id
      JOIN users guest ON guest.id = b.user_id
      WHERE h.owner_id = ${req.user.id}::uuid
      ORDER BY b.created_at DESC
    `;
    ok(res, bookings);
  }),
);

ownerBookingRoutes.patch(
  '/:id/confirm',
  authRequired,
  requireRole('OWNER'),
  asyncHandler(async (req, res) => {
    const [booking] = await prisma.$queryRaw`
      UPDATE hotel_bookings b
      SET status = 'CONFIRMED'
      FROM hotels h
      WHERE b.id = ${req.params.id}::uuid
        AND b.hotel_id = h.id
        AND h.owner_id = ${req.user.id}::uuid
        AND b.status = 'PENDING'
      RETURNING b.id::text AS id, b.reference, b.status
    `;
    if (!booking) throw notFound('Pending booking not found for your hotel.');
    ok(res, booking);
  }),
);

const PrismaRawBookingSelect = `
  b.id::text AS id,
  b.reference,
  b.check_in::text AS "checkIn",
  b.check_out::text AS "checkOut",
  b.guests,
  b.nights,
  b.total_price::float8 AS "totalPrice",
  b.status,
  b.created_at AS "createdAt",
  json_build_object('id', h.id::text, 'name', h.name, 'city', h.city) AS hotel,
  json_build_object(
    'fullName', COALESCE(b.guest_name, guest.full_name),
    'email', guest.email,
    'phone', COALESCE(b.guest_phone, guest.phone)
  ) AS "user",
  json_build_object('name', 'Standard room') AS "roomType"
`;

export default router;
