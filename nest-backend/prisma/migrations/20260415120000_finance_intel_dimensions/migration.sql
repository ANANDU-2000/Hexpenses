-- Enums (idempotent: deploy retries / partial failures / db push drift)
DO $$ BEGIN
  CREATE TYPE "EntityKind" AS ENUM ('vehicle', 'person', 'vendor', 'donation_recipient', 'other');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "PaymentMode" AS ENUM ('cash', 'card', 'upi', 'bank_transfer', 'wallet', 'other');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- SubCategory.sortOrder (safe if column already exists from manual/db push)
ALTER TABLE "SubCategory" ADD COLUMN IF NOT EXISTS "sortOrder" INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS "SubCategory_categoryId_sortOrder_idx" ON "SubCategory"("categoryId", "sortOrder");

-- CreateTable
CREATE TABLE IF NOT EXISTS "ExpenseTypeDef" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "subCategoryId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameKey" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "ExpenseTypeDef_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "SpendEntity" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "workspaceId" TEXT,
    "categoryId" TEXT NOT NULL,
    "subCategoryId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameKey" TEXT NOT NULL,
    "kind" "EntityKind" NOT NULL DEFAULT 'other',
    "vehicleId" TEXT,
    "metadata" JSONB,

    CONSTRAINT "SpendEntity_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "ExpenseTypeDef_subCategoryId_nameKey_key" ON "ExpenseTypeDef"("subCategoryId", "nameKey");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "ExpenseTypeDef_userId_idx" ON "ExpenseTypeDef"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "ExpenseTypeDef_subCategoryId_sortOrder_idx" ON "ExpenseTypeDef"("subCategoryId", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "SpendEntity_vehicleId_key" ON "SpendEntity"("vehicleId");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "SpendEntity_subCategoryId_nameKey_key" ON "SpendEntity"("subCategoryId", "nameKey");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "SpendEntity_userId_categoryId_idx" ON "SpendEntity"("userId", "categoryId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "SpendEntity_workspaceId_idx" ON "SpendEntity"("workspaceId");

-- AddForeignKey (skip if already applied)
DO $$ BEGIN
  ALTER TABLE "ExpenseTypeDef" ADD CONSTRAINT "ExpenseTypeDef_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "ExpenseTypeDef" ADD CONSTRAINT "ExpenseTypeDef_subCategoryId_fkey" FOREIGN KEY ("subCategoryId") REFERENCES "SubCategory"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "SpendEntity" ADD CONSTRAINT "SpendEntity_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "SpendEntity" ADD CONSTRAINT "SpendEntity_workspaceId_fkey" FOREIGN KEY ("workspaceId") REFERENCES "Workspace"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "SpendEntity" ADD CONSTRAINT "SpendEntity_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "SpendEntity" ADD CONSTRAINT "SpendEntity_subCategoryId_fkey" FOREIGN KEY ("subCategoryId") REFERENCES "SubCategory"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "SpendEntity" ADD CONSTRAINT "SpendEntity_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Expense columns (idempotent)
ALTER TABLE "Expense" ADD COLUMN IF NOT EXISTS "expenseTypeId" TEXT;
ALTER TABLE "Expense" ADD COLUMN IF NOT EXISTS "spendEntityId" TEXT;
ALTER TABLE "Expense" ADD COLUMN IF NOT EXISTS "paymentMode" "PaymentMode";

DO $$ BEGIN
  ALTER TABLE "Expense" ADD CONSTRAINT "Expense_expenseTypeId_fkey" FOREIGN KEY ("expenseTypeId") REFERENCES "ExpenseTypeDef"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "Expense" ADD CONSTRAINT "Expense_spendEntityId_fkey" FOREIGN KEY ("spendEntityId") REFERENCES "SpendEntity"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS "Expense_userId_subCategoryId_date_idx" ON "Expense"("userId", "subCategoryId", "date");

CREATE INDEX IF NOT EXISTS "Expense_userId_expenseTypeId_date_idx" ON "Expense"("userId", "expenseTypeId", "date");

CREATE INDEX IF NOT EXISTS "Expense_userId_spendEntityId_date_idx" ON "Expense"("userId", "spendEntityId", "date");

CREATE INDEX IF NOT EXISTS "Expense_paymentMode_idx" ON "Expense"("paymentMode");

ALTER TABLE "Document" ADD COLUMN IF NOT EXISTS "expenseId" TEXT;

DO $$ BEGIN
  ALTER TABLE "Document" ADD CONSTRAINT "Document_expenseId_fkey" FOREIGN KEY ("expenseId") REFERENCES "Expense"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS "Document_expenseId_idx" ON "Document"("expenseId");
