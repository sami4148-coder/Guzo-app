ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "hotel_name" VARCHAR(150),
  ADD COLUMN IF NOT EXISTS "business_address" VARCHAR(255),
  ADD COLUMN IF NOT EXISTS "owner_status" VARCHAR(20) NOT NULL DEFAULT 'APPROVED';

UPDATE "users"
SET "owner_status" = 'PENDING'
WHERE "role"::text = 'OWNER'
  AND "is_active" = FALSE
  AND "owner_status" = 'APPROVED';

ALTER TABLE "hotels"
  ADD COLUMN IF NOT EXISTS "rooms_available" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS "amenities" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS "other_details" TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS "hotel_bookings" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "reference" VARCHAR(32) NOT NULL UNIQUE,
  "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "hotel_id" UUID NOT NULL REFERENCES "hotels"("id") ON DELETE CASCADE,
  "check_in" DATE NOT NULL,
  "check_out" DATE NOT NULL,
  "guests" INTEGER NOT NULL CHECK ("guests" > 0),
  "nights" INTEGER NOT NULL CHECK ("nights" > 0),
  "total_price" BIGINT NOT NULL CHECK ("total_price" > 0),
  "status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
  CHECK ("check_out" > "check_in")
);

ALTER TABLE "hotel_bookings"
  ADD COLUMN IF NOT EXISTS "guest_name" VARCHAR(120),
  ADD COLUMN IF NOT EXISTS "guest_phone" VARCHAR(30);

CREATE INDEX IF NOT EXISTS "hotel_bookings_hotel_dates_status_idx"
  ON "hotel_bookings" ("hotel_id", "check_in", "check_out", "status");
CREATE INDEX IF NOT EXISTS "hotel_bookings_user_created_at_idx"
  ON "hotel_bookings" ("user_id", "created_at" DESC);

CREATE TABLE IF NOT EXISTS "user_notifications" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "hotel_id" UUID NOT NULL REFERENCES "hotels"("id") ON DELETE CASCADE,
  "title" VARCHAR(150) NOT NULL,
  "message" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
  "read_at" TIMESTAMPTZ(6)
);

CREATE INDEX IF NOT EXISTS "user_notifications_user_created_at_idx"
  ON "user_notifications" ("user_id", "created_at" DESC);
