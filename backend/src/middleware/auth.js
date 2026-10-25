import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { prisma } from '../config/database.js';
import { unauthorized, forbidden } from '../utils/errors.js';

export const signToken = (user) =>
  jwt.sign({ sub: user.id, role: user.role }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });

export const authRequired = async (req, _res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(unauthorized('Missing token'));

  let payload;
  try {
    payload = jwt.verify(token, env.jwtSecret);
  } catch {
    return next(unauthorized('Invalid or expired token'));
  }

  try {
    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        fullName: true,
        isActive: true,
      },
    });
    if (!user || !user.isActive) return next(unauthorized('Invalid account'));
    req.user = user;
  } catch (err) {
    return next(err);
  }
  return next();
};

export const requireRole = (...roles) => (req, _res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(forbidden('Insufficient permissions'));
  }
  next();
};