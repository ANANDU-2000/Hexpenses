-- CreateEnum
CREATE TYPE "InvestmentKind" AS ENUM ('stock', 'sip', 'crypto', 'other');

-- AlterTable
ALTER TABLE "Investment" ADD COLUMN "kind" "InvestmentKind" NOT NULL DEFAULT 'other',
ADD COLUMN "investedAmount" DECIMAL(12,2),
ADD COLUMN "note" TEXT;

UPDATE "Investment" SET "investedAmount" = "currentValue" WHERE "investedAmount" IS NULL;

ALTER TABLE "Investment" ALTER COLUMN "investedAmount" SET NOT NULL;

CREATE INDEX "Investment_userId_kind_idx" ON "Investment"("userId", "kind");
