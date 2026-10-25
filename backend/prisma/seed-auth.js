import bcrypt from 'bcryptjs';
import { prisma } from '../src/config/database.js';

const demoAccounts = [
  { email: 'admin@guzo.demo', fullName: 'GUZO Admin', role: 'ADMIN' },
  { email: 'owner@guzo.demo', fullName: 'Demo Owner', role: 'OWNER' },
  { email: 'traveler@guzo.demo', fullName: 'Demo Traveler', role: 'TRAVELER' },
];

async function main() {
  const demoPasswordHash = await bcrypt.hash('Password123!', 12);
  const adminPasswordHash = await bcrypt.hash(
    process.env.ADMIN_PASSWORD || 'Password123!',
    12,
  );

  for (const account of demoAccounts) {
    const isAdmin = account.role === 'ADMIN';
    await prisma.user.upsert({
      where: { email: account.email },
      update: {
        ...account,
        ...(isAdmin && process.env.ADMIN_PASSWORD
          ? { passwordHash: adminPasswordHash }
          : {}),
        ...(!isAdmin ? { passwordHash: demoPasswordHash } : {}),
        isActive: true,
      },
      create: {
        ...account,
        passwordHash: isAdmin ? adminPasswordHash : demoPasswordHash,
      },
    });
  }

  console.log('Authentication demo accounts are ready.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
