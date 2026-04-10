-- CreateEnum
CREATE TYPE "IncomeSource" AS ENUM ('salary', 'business', 'other');

-- CreateTable
CREATE TABLE "Income" (
    "id" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "source" "IncomeSource" NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "note" TEXT,
    "userId" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Income_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Income_userId_date_idx" ON "Income"("userId", "date" DESC);

-- CreateIndex
CREATE INDEX "Income_userId_accountId_idx" ON "Income"("userId", "accountId");

-- CreateIndex
CREATE INDEX "Income_userId_source_idx" ON "Income"("userId", "source");

-- AddForeignKey
ALTER TABLE "Income" ADD CONSTRAINT "Income_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Income" ADD CONSTRAINT "Income_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
