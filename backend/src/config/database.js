import { PrismaClient } from '@prisma/client';
import { env } from './env.js';

const globalForPrisma = globalThis;

export const prisma =
  globalForPrisma.guzoPrisma ??
  new PrismaClient({
    log: env.nodeEnv === 'development' ? ['warn', 'error'] : ['error'],
  });

if (env.nodeEnv !== 'production') {
  globalForPrisma.guzoPrisma = prisma;
}

export const connectDatabase = () => prisma.$connect();
export const disconnectDatabase = () => prisma.$disconnect();
