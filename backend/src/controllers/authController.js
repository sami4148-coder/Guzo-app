import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { prisma } from '../config/database.js';
import { asyncHandler } from '../utils/async.js';
import { ok, created } from '../utils/response.js';
import { conflict, forbidden, unauthorized } from '../utils/errors.js';
import { signToken } from '../middleware/auth.js';

export const registerSchema = z.object({
  email: z.string().trim().email().transform((email) => email.toLowerCase()),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  fullName: z.string().trim().min(2).max(120).optional(),
  phone: z.string().trim().max(30).optional(),
  role: z.enum(['TRAVELER', 'OWNER']).optional(), // ADMIN not self-assignable
  hotelName: z.string().trim().min(2).max(150).optional(),
  businessAddress: z.string().trim().min(5).max(255).optional(),
}).superRefine((data, context) => {
  if (data.role === 'OWNER') {
    if (!data.hotelName) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['hotelName'],
        message: 'Hotel name is required for owner accounts',
      });
    }
    if (!data.businessAddress) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['businessAddress'],
        message: 'Business address is required for owner accounts',
      });
    }
    if (!data.phone) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['phone'],
        message: 'Phone number is required for owner accounts',
      });
    }
  } else if (!data.fullName) {
    context.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['fullName'],
      message: 'Full name is required',
    });
  }
});

export const loginSchema = z.object({
  email: z.string().trim().email().transform((email) => email.toLowerCase()),
  password: z.string().min(1),
});

export const updateProfileSchema = z.object({
  fullName: z.string().trim().min(2).max(120),
});

export const register = asyncHandler(async (req, res) => {
  const {
    email, password, fullName, phone, role = 'TRAVELER',
    hotelName, businessAddress,
  } = req.body;
  const passwordHash = await bcrypt.hash(password, 12);
  let user;
  try {
    user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        fullName: fullName || hotelName,
        phone: phone || null,
        role,
        hotelName: role === 'OWNER' ? hotelName : null,
        businessAddress: role === 'OWNER' ? businessAddress : null,
        isActive: role !== 'OWNER',
        ownerStatus: role === 'OWNER' ? 'PENDING' : 'APPROVED',
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        role: true,
        isActive: true,
        ownerStatus: true,
        createdAt: true,
      },
    });
  } catch (error) {
    if (error.code === 'P2002') throw conflict('Email already registered');
    throw error;
  }

  created(res, {
    user,
    approvalPending: role === 'OWNER',
  });
});

export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw unauthorized('Invalid email or password');

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) throw unauthorized('Invalid email or password');
  if (user.role === 'OWNER' && user.ownerStatus === 'BANNED') {
    throw forbidden('Your hotel owner account has been banned. Contact the administrator for assistance.');
  }
  if (user.role === 'OWNER' && user.ownerStatus === 'PENDING') {
    throw forbidden('Your hotel owner account is awaiting admin approval.');
  }
  if (!user.isActive) throw unauthorized('Invalid email or password');

  const token = signToken(user);
  ok(res, {
    user: {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
    },
    token,
  });
});

export const me = asyncHandler(async (req, res) => {
  ok(res, { user: req.user });
});

export const updateProfile = asyncHandler(async (req, res) => {
  const user = await prisma.user.update({
    where: { id: req.user.id },
    data: { fullName: req.body.fullName },
    select: {
      id: true,
      email: true,
      fullName: true,
      phone: true,
      role: true,
    },
  });
  ok(res, { user });
});