-- AlterTable
ALTER TABLE "RefreshToken" ADD COLUMN "sessionId" TEXT,
ADD COLUMN "deviceLabel" TEXT,
ADD COLUMN "lastIpHash" TEXT,
ADD COLUMN "lastUsedAt" TIMESTAMP(3),
ADD COLUMN "rotatedFromId" TEXT;

UPDATE "RefreshToken" SET "sessionId" = gen_random_uuid()::text WHERE "sessionId" IS NULL;

ALTER TABLE "RefreshToken" ALTER COLUMN "sessionId" SET NOT NULL;

CREATE UNIQUE INDEX "RefreshToken_sessionId_key" ON "RefreshToken"("sessionId");
