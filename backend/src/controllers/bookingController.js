import { z } from 'zod';
import { prisma } from '../config/database.js';
import { asyncHandler } from '../utils/async.js';
import { ok, created } from '../utils/response.js';
import { badRequest, conflict, forbidden, notFound } from '../utils/errors.js';
import { generateBookingReference } from '../utils/reference.js';

export const bookingCreateSchema = z.object({
  hotelId: z.string(),
  roomTypeId: z.string(),
  checkIn: z.string().datetime().or(z.string()),
  checkOut: z.string().datetime().or(z.string()),
  guests: z.number().int().positive(),
});

const MS_PER_DAY = 86400000;

// POST /api/bookings
export const createBooking = asyncHandler(async (req, res) => {
  const { hotelId, roomTypeId, checkIn, checkOut, guests } = req.body;

  const checkInDate = new Date(checkIn);
  const checkOutDate = new Date(checkOut);

  if (isNaN(checkInDate) || isNaN(checkOutDate)) throw badRequest('Invalid dates');
  if (checkOutDate <= checkInDate) throw badRequest('Check-out must be after check-in');

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  if (checkInDate < today) throw badRequest('Check-in cannot be in the past');

  const nights = Math.round((checkOutDate - checkInDate) / MS_PER_DAY);

  // Wrap in transaction for concurrency-safe availability check
  const result = await prisma.$transaction(async (tx) => {
    const room = await tx.roomType.findUnique({
      where: { id: roomTypeId },
      include: { hotel: true },
    });
    if (!room) throw notFound('Room type not found');
    if (room.hotelId !== hotelId) throw badRequest('Room does not belong to hotel');
    if (room.hotel.status !== 'APPROVED') throw badRequest('Hotel is not available for booking');
    if (guests > room.maxGuests) throw badRequest(`Room allows max ${room.maxGuests} guests`);

    // Count overlapping active bookings
    const overlapping = await tx.booking.count({
      where: {
        roomTypeId,
        status: { in: ['PENDING', 'CONFIRMED'] },
        AND: [
          { checkIn: { lt: checkOutDate } },
          { checkOut: { gt: checkInDate } },
        ],
      },
    });

    if (overlapping >= room.totalRooms) {
      throw conflict('No rooms available for the selected dates', 'ROOM_UNAVAILABLE');
    }

    // Server-side price calculation
    const totalPrice = room.pricePerNight * nights;

    const booking = await tx.booking.create({
      data: {
        reference: generateBookingReference(),
        userId: req.user.id,
        hotelId,
        roomTypeId,
        checkIn: checkInDate,
        checkOut: checkOutDate,
        guests,
        nights,
        totalPrice,
        status: 'PENDING',
      },
      include: {
        hotel: { select: { id: true, name: true, city: true } },
        roomType: { select: { id: true, name: true } },
      },
    });

    return booking;
  });

  created(res, result);
});

// GET /api/bookings/my
export const myBookings = asyncHandler(async (req, res) => {
  const bookings = await prisma.booking.findMany({
    where: { userId: req.user.id },
    orderBy: { createdAt: 'desc' },
    include: {
      hotel: { select: { id: true, name: true, city: true, images: { take: 1 } } },
      roomType: { select: { id: true, name: true } },
    },
  });
  ok(res, bookings);
});

// GET /api/bookings/:id
export const getBooking = asyncHandler(async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id },
    include: { hotel: true, roomType: true, user: { select: { id: true, email: true, fullName: true } } },
  });
  if (!booking) throw notFound('Booking not found');

  const isOwner = booking.userId === req.user.id;
  const isHotelOwner = req.user.role === 'OWNER';
  const isAdmin = req.user.role === 'ADMIN';

  if (!isOwner && !isAdmin) {
    if (isHotelOwner) {
      const hotel = await prisma.hotel.findUnique({ where: { id: booking.hotelId } });
      if (!hotel || hotel.ownerId !== req.user.id) throw forbidden('Not your booking');
    } else {
      throw forbidden('Not your booking');
    }
  }

  ok(res, booking);
});

// PATCH /api/bookings/:id/cancel
export const cancelBooking = asyncHandler(async (req, res) => {
  const booking = await prisma.booking.findUnique({ where: { id: req.params.id } });
  if (!booking) throw notFound('Booking not found');
  if (booking.userId !== req.user.id && req.user.role !== 'ADMIN') {
    throw forbidden('Not your booking');
  }
  if (booking.status === 'CANCELLED') throw conflict('Already cancelled');
  if (booking.status === 'COMPLETED') throw conflict('Completed bookings cannot be cancelled');

  // Cancellation rule: at least 24h before check-in
  const hoursUntilCheckIn = (booking.checkIn - new Date()) / 3600000;
  if (req.user.role !== 'ADMIN' && hoursUntilCheckIn < 24) {
    throw conflict('Cancellation not allowed within 24 hours of check-in', 'CANCELLATION_WINDOW');
  }

  const updated = await prisma.booking.update({
    where: { id: booking.id },
    data: { status: 'CANCELLED' },
  });
  ok(res, updated);
});

// GET /api/rooms/:id/availability?checkIn=&checkOut=
export const checkAvailability = asyncHandler(async (req, res) => {
  const { checkIn, checkOut } = req.query;
  if (!checkIn || !checkOut) throw badRequest('checkIn and checkOut are required');
  const ci = new Date(checkIn);
  const co = new Date(checkOut);
  if (isNaN(ci) || isNaN(co) || co <= ci) throw badRequest('Invalid date range');

  const room = await prisma.roomType.findUnique({ where: { id: req.params.id } });
  if (!room) throw notFound('Room not found');

  const overlapping = await prisma.booking.count({
    where: {
      roomTypeId: room.id,
      status: { in: ['PENDING', 'CONFIRMED'] },
      AND: [{ checkIn: { lt: co } }, { checkOut: { gt: ci } }],
    },
  });

  const availableRooms = Math.max(0, room.totalRooms - overlapping);
  const nights = Math.round((co - ci) / MS_PER_DAY);
  ok(res, {
    hotelId: room.hotelId,
    roomTypeId: room.id,
    nights,
    availableRooms,
    totalPrice: room.pricePerNight * nights,
    pricePerNight: room.pricePerNight,
  });
});