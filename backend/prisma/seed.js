import bcrypt from 'bcryptjs';
import { prisma } from '../src/config/database.js';

// ⚠️  DEMO DATA — NOT REAL HOTELS. For local development only.
const HOTELS = [
  {
    name: '[DEMO] Skylight Grand',
    city: 'Addis Ababa',
    address: 'Bole Road, Addis Ababa',
    description: 'A modern city hotel in the heart of Bole with skyline views and conference facilities.',
    category: 'luxury',
    basePrice: 6500,
    rating: 4.7,
    images: [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200',
      'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=1200',
    ],
    amenities: ['WiFi', 'Pool', 'Gym', 'Restaurant', 'Parking'],
    rooms: [
      { name: 'Deluxe King', maxGuests: 2, pricePerNight: 6500, totalRooms: 10 },
      { name: 'Executive Suite', maxGuests: 3, pricePerNight: 11000, totalRooms: 5 },
    ],
  },
  {
    name: '[DEMO] Lalibela Rock View Lodge',
    city: 'Lalibela',
    address: 'Near Rock-Hewn Churches, Lalibela',
    description: 'Boutique lodge overlooking the historic rock-hewn churches of Lalibela.',
    category: 'resort',
    basePrice: 3200,
    rating: 4.6,
    images: [
      'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200',
      'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=1200',
    ],
    amenities: ['WiFi', 'Restaurant', 'Tour Desk'],
    rooms: [
      { name: 'Garden Room', maxGuests: 2, pricePerNight: 3200, totalRooms: 8 },
      { name: 'Heritage Suite', maxGuests: 3, pricePerNight: 5800, totalRooms: 3 },
    ],
  },
  {
    name: '[DEMO] Hawassa Lake Resort',
    city: 'Hawassa',
    address: 'Lake Hawassa Shoreline',
    description: 'Lakeside resort with sunset views and traditional Sidama cuisine.',
    category: 'resort',
    basePrice: 4500,
    rating: 4.5,
    images: [
      'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=1200',
      'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=1200',
    ],
    amenities: ['WiFi', 'Pool', 'Restaurant', 'Lake View'],
    rooms: [
      { name: 'Lake View Double', maxGuests: 2, pricePerNight: 4500, totalRooms: 12 },
      { name: 'Family Cabin', maxGuests: 5, pricePerNight: 7200, totalRooms: 4 },
    ],
  },
  {
    name: '[DEMO] Bahir Dar Blue Nile Hotel',
    city: 'Bahir Dar',
    address: 'Near Blue Nile Falls Road',
    description: 'Comfortable stay near the Blue Nile with easy access to Lake Tana monasteries.',
    category: 'budget',
    basePrice: 1800,
    rating: 4.2,
    images: [
      'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=1200',
    ],
    amenities: ['WiFi', 'Restaurant', 'Parking'],
    rooms: [
      { name: 'Standard Twin', maxGuests: 2, pricePerNight: 1800, totalRooms: 15 },
    ],
  },
  {
    name: '[DEMO] Gondar Castle Guesthouse',
    city: 'Gondar',
    address: 'Near Fasil Ghebbi',
    description: 'Charming guesthouse a short walk from the royal castles of Gondar.',
    category: 'guesthouse',
    basePrice: 1500,
    rating: 4.4,
    images: [
      'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=1200',
    ],
    amenities: ['WiFi', 'Breakfast'],
    rooms: [
      { name: 'Classic Room', maxGuests: 2, pricePerNight: 1500, totalRooms: 6 },
    ],
  },
  {
    name: '[DEMO] Arba Minch Rift Valley Lodge',
    city: 'Arba Minch',
    address: 'Nechisar Road',
    description: 'Overlooking the Rift Valley lakes with views of the "Bridge of God".',
    category: 'resort',
    basePrice: 3800,
    rating: 4.6,
    images: [
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=1200',
    ],
    amenities: ['WiFi', 'Pool', 'Restaurant'],
    rooms: [
      { name: 'Rift View Room', maxGuests: 2, pricePerNight: 3800, totalRooms: 10 },
    ],
  },
];

async function main() {
  console.log('🌱 Seeding GUZO database…');

  const passwordHash = await bcrypt.hash('Password123!', 12);
  const adminPasswordHash = await bcrypt.hash(
    process.env.ADMIN_PASSWORD || 'Password123!',
    12,
  );

  const admin = await prisma.user.upsert({
    where: { email: 'admin@guzo.demo' },
    update: {
      ...(process.env.ADMIN_PASSWORD
        ? { passwordHash: adminPasswordHash }
        : {}),
      isActive: true,
    },
    create: {
      email: 'admin@guzo.demo',
      fullName: 'GUZO Admin',
      passwordHash: adminPasswordHash,
      role: 'ADMIN',
    },
  });

  const owner = await prisma.user.upsert({
    where: { email: 'owner@guzo.demo' },
    update: { passwordHash, isActive: true },
    create: { email: 'owner@guzo.demo', fullName: 'Demo Owner', passwordHash, role: 'OWNER' },
  });

  await prisma.user.upsert({
    where: { email: 'traveler@guzo.demo' },
    update: { passwordHash, isActive: true },
    create: { email: 'traveler@guzo.demo', fullName: 'Demo Traveler', passwordHash, role: 'TRAVELER' },
  });

  const amenityNames = ['WiFi', 'Pool', 'Gym', 'Restaurant', 'Parking', 'Breakfast', 'Tour Desk', 'Lake View'];
  for (const name of amenityNames) {
    await prisma.amenity.upsert({ where: { name }, create: { name }, update: {} });
  }

  for (const h of HOTELS) {
    const existing = await prisma.hotel.findFirst({ where: { name: h.name } });
    if (existing) continue;

    await prisma.hotel.create({
      data: {
        name: h.name,
        city: h.city,
        address: h.address,
        description: h.description,
        category: h.category,
        basePrice: h.basePrice,
        rating: h.rating,
        status: 'APPROVED',
        ownerId: owner.id,
        images: { create: h.images.map((url, i) => ({ url, isCover: i === 0 })) },
        amenities: {
          create: await Promise.all(
            h.amenities.map(async (name) => {
              const a = await prisma.amenity.findUnique({ where: { name } });
              return { amenityId: a.id };
            })
          ),
        },
        roomTypes: { create: h.rooms },
      },
    });
  }

  console.log('✅ Seed complete.');
  console.log('   admin@guzo.demo    / Password123!');
  console.log('   owner@guzo.demo    / Password123!');
  console.log('   traveler@guzo.demo / Password123!');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());