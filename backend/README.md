# GUZO Backend

REST API for the GUZO Ethiopian hotel booking platform.

## Setup

### Local PostgreSQL for testing

From the `backend` directory, start a development-only PostgreSQL instance:

```bash
docker compose up -d postgres
```

Copy `.env.example` to `.env` and set `DATABASE_URL` to
`postgresql://guzo:guzo_dev_password@localhost:5432/guzo?schema=public`.
For a fresh local database, initialize the Prisma schema and seed the
authentication demo accounts:

```bash
npm install
npm run prisma:generate
npm run prisma:migrate
npm run db:owner-fields
npm run seed:auth
npm run dev
```

For an existing GUZO database, apply the owner/listing columns with
`npm run db:owner-fields` before starting the updated API. The SQL is
idempotent, preserves existing rows, and creates the hotel booking and
notification tables. Run it again when updating an existing database with
new owner/listing features.
Hotel owner accounts remain pending
until an admin accepts them; admins can also ban accepted or pending owners.
Banned owners cannot sign in, use owner APIs, or have their hotel listings
shown to travelers.

Do not run the initial migration against a populated database without first
backing it up and reviewing the migration. The API uses the PostgreSQL database
configured by `DATABASE_URL` through `src/config/database.js`.

Server runs on `http://localhost:4000`.
Confirm it is available at `http://localhost:4000/health` before signing in.
For local Flutter web testing, development CORS accepts localhost origins on
any port (Flutter's web server may choose a different port each run).

The Flutter app defaults to `http://localhost:4000/api` on web and desktop,
and `http://10.0.2.2:4000/api` on the Android emulator. To use another API
address, set `API_BASE_URL` in `frontend/.env` or pass
`--dart-define=API_BASE_URL=http://192.168.1.20:4000/api` when starting Flutter.
The compile-time value takes precedence over `.env`. For a physical Android
phone, use the computer's LAN address and ensure both devices are on the same
network and the computer firewall allows inbound connections to port `4000`.
Restart the Flutter app after changing `.env`.

The login page's **Continue as demo traveler** button signs in with
`traveler@guzo.demo` / `Password123!`. Seeding resets the owner and traveler
demo passwords. The admin password is preserved when reseeding; set
`ADMIN_PASSWORD` in `backend/.env` only when intentionally creating or resetting
the seeded admin account password.

The Compose database credentials and demo accounts are for local development
only. Do not use them in production.

## Demo accounts (seeded)

| Role     | Email                | Password     |
|----------|----------------------|--------------|
| Admin    | admin@guzo.demo      | Configured locally |
| Owner    | owner@guzo.demo      | Password123! |
| Traveler | traveler@guzo.demo   | Password123! |

⚠️ Seeded hotels are clearly labelled `[DEMO]` and are **not real properties**.

## Key Endpoints

```
POST   /api/auth/register
POST   /api/auth/login
GET    /api/auth/me
PATCH  /api/auth/me              (auth; update fullName)

GET    /api/hotels?city=&category=&minPrice=&maxPrice=&minRating=&guests=&sort=&page=&limit=
GET    /api/hotels/:id
GET    /api/hotels/:id/availability?checkIn=&checkOut=
GET    /api/hotels/mine          (OWNER)
POST   /api/hotels                (OWNER/ADMIN)
PATCH  /api/hotels/:id            (OWNER/ADMIN)
DELETE /api/hotels/:id            (OWNER/ADMIN)

GET    /api/notifications         (TRAVELER)
PATCH  /api/notifications/:id/read (TRAVELER)

POST   /api/bookings              (auth)
GET    /api/bookings/my           (auth)

GET    /api/owner/bookings        (OWNER)
PATCH  /api/owner/bookings/:id/confirm

GET    /api/admin/stats           (ADMIN)
GET    /api/admin/hotels          (ADMIN)
PATCH  /api/admin/hotels/:id/approve
PATCH  /api/admin/hotels/:id/suspend
```

## Booking safety

- Server recomputes nights + total price (client totals are ignored).
- Overlapping PENDING/CONFIRMED bookings are checked inside a database transaction.
- New owner listings are available on Explore as soon as they are published.
- Publishing a hotel listing creates an in-app notification for each active
  traveler. Travelers can view notifications from the app bell and open the
  listing directly from the inbox.
- Traveler reservations are stored and listed for the selected hotel owner at
  `GET /api/owner/bookings`, including the guest-provided name and phone
  number, stay dates, guest count, total price, and status. Travelers provide
  their name and contact number when booking. The owner dashboard refreshes
  reservations automatically and only that owner can confirm them.
- Bookings exceed capacity → `409 ROOM_UNAVAILABLE`.
- Cancellation allowed only ≥24h before check-in (admin override).

## Sample request

```bash
curl -X POST http://localhost:4000/api/bookings \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "hotelId": "...",
    "checkIn": "2026-11-01",
    "checkOut": "2026-11-03",
    "guests": 2,
    "guestName": "Guest Name",
    "phone": "+251 911 234 567"
  }'
```