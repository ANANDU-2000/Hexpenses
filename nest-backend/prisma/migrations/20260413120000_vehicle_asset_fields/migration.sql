-- AlterTable
ALTER TABLE "Vehicle" ADD COLUMN     "vehicleType" TEXT NOT NULL DEFAULT 'car',
ADD COLUMN "purchaseDate" TIMESTAMP(3),
ADD COLUMN "purchasePrice" DECIMAL(14,2),
ADD COLUMN "currentValue" DECIMAL(14,2),
ADD COLUMN "insuranceExpiryDate" TIMESTAMP(3);
