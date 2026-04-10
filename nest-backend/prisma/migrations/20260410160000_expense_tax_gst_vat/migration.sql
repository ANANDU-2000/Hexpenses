-- CreateEnum
CREATE TYPE "ExpenseTaxScheme" AS ENUM ('gst_in', 'vat_ae');

-- AlterTable
ALTER TABLE "Expense" ADD COLUMN "taxable" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "taxScheme" "ExpenseTaxScheme",
ADD COLUMN "taxAmount" DECIMAL(12,2);

CREATE INDEX "Expense_userId_workspaceId_taxable_date_idx" ON "Expense"("userId", "workspaceId", "taxable", "date" DESC);
