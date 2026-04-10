-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('owner', 'manager', 'family');

-- CreateEnum
CREATE TYPE "CategoryType" AS ENUM ('expense', 'income');

-- CreateEnum
CREATE TYPE "Frequency" AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'yearly');

-- CreateEnum
CREATE TYPE "RecurringStatus" AS ENUM ('pending', 'paid', 'missed');

-- CreateEnum
CREATE TYPE "RecurringMode" AS ENUM ('auto_create', 'reminder_only');

-- CreateEnum
CREATE TYPE "ExpenseSource" AS ENUM ('manual', 'whatsapp', 'recurring_generated', 'import');

-- CreateEnum
CREATE TYPE "NotificationChannel" AS ENUM ('in_app', 'whatsapp', 'push');

-- CreateEnum
CREATE TYPE "NotificationCategory" AS ENUM ('recurring', 'insurance', 'emi', 'system', 'ai');

-- CreateEnum
CREATE TYPE "AiInsightType" AS ENUM ('spending_summary', 'anomaly', 'monthly_prediction');

-- CreateEnum
CREATE TYPE "AiInsightStatus" AS ENUM ('pending', 'ready', 'failed');

-- CreateEnum
CREATE TYPE "WhatsAppMessageStatus" AS ENUM ('received', 'parsed', 'applied', 'failed');

-- CreateEnum
CREATE TYPE "WhatsAppProvider" AS ENUM ('twilio', 'meta');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "passwordHash" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "role" "UserRole" NOT NULL DEFAULT 'owner',
    "timeZone" TEXT NOT NULL DEFAULT 'UTC',
    "locale" TEXT NOT NULL DEFAULT 'en',
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OTPChallenge" (
    "id" TEXT NOT NULL,
    "mobileNumber" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "isUsed" BOOLEAN NOT NULL DEFAULT false,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT,

    CONSTRAINT "OTPChallenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Category" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "CategoryType" NOT NULL DEFAULT 'expense',
    "userId" TEXT NOT NULL,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubCategory" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,

    CONSTRAINT "SubCategory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Expense" (
    "id" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "categoryId" TEXT NOT NULL,
    "subCategoryId" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "note" TEXT,
    "userId" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "source" "ExpenseSource" NOT NULL DEFAULT 'manual',
    "metadata" JSONB,
    "vehicleId" TEXT,
    "recurringExpenseId" TEXT,
    "whatsappMessageId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Expense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RecurringExpense" (
    "id" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "frequency" "Frequency" NOT NULL,
    "mode" "RecurringMode" NOT NULL DEFAULT 'auto_create',
    "status" "RecurringStatus" NOT NULL DEFAULT 'pending',
    "nextDate" TIMESTAMP(3) NOT NULL,
    "categoryId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "note" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "RecurringExpense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Insurance" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "premium" DECIMAL(12,2) NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "expiryDate" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT,
    "policyNumber" TEXT,
    "reminderDaysBefore" INTEGER NOT NULL DEFAULT 7,
    "documentId" TEXT,

    CONSTRAINT "Insurance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vehicle" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VehicleExpense" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VehicleExpense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Document" (
    "id" TEXT NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "uploadedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT,
    "channel" "NotificationChannel" NOT NULL DEFAULT 'in_app',
    "category" "NotificationCategory" NOT NULL DEFAULT 'system',
    "date" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,
    "readAt" TIMESTAMP(3),
    "dedupeKey" TEXT,
    "relatedType" TEXT,
    "relatedId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AiInsight" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "AiInsightType" NOT NULL,
    "status" "AiInsightStatus" NOT NULL DEFAULT 'pending',
    "periodStart" TIMESTAMP(3),
    "periodEnd" TIMESTAMP(3),
    "summary" TEXT,
    "payload" JSONB,
    "openaiModel" TEXT,
    "promptTokens" INTEGER,
    "completionTokens" INTEGER,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AiInsight_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserWhatsAppLink" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "phoneE164" TEXT NOT NULL,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserWhatsAppLink_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WhatsAppInboundMessage" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "provider" "WhatsAppProvider" NOT NULL,
    "providerMessageId" TEXT NOT NULL,
    "rawBody" TEXT NOT NULL,
    "parsedPayload" JSONB,
    "status" "WhatsAppMessageStatus" NOT NULL DEFAULT 'received',
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WhatsAppInboundMessage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_tokenHash_key" ON "RefreshToken"("tokenHash");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- CreateIndex
CREATE INDEX "OTPChallenge_mobileNumber_idx" ON "OTPChallenge"("mobileNumber");

-- CreateIndex
CREATE INDEX "Category_userId_type_idx" ON "Category"("userId", "type");

-- CreateIndex
CREATE UNIQUE INDEX "Category_userId_name_key" ON "Category"("userId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "SubCategory_categoryId_name_key" ON "SubCategory"("categoryId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Expense_whatsappMessageId_key" ON "Expense"("whatsappMessageId");

-- CreateIndex
CREATE INDEX "Expense_userId_date_idx" ON "Expense"("userId", "date" DESC);

-- CreateIndex
CREATE INDEX "Expense_userId_categoryId_date_idx" ON "Expense"("userId", "categoryId", "date");

-- CreateIndex
CREATE INDEX "Expense_userId_source_idx" ON "Expense"("userId", "source");

-- CreateIndex
CREATE INDEX "Expense_categoryId_date_idx" ON "Expense"("categoryId", "date");

-- CreateIndex
CREATE INDEX "RecurringExpense_userId_nextDate_idx" ON "RecurringExpense"("userId", "nextDate");

-- CreateIndex
CREATE INDEX "RecurringExpense_active_nextDate_idx" ON "RecurringExpense"("active", "nextDate");

-- CreateIndex
CREATE INDEX "Insurance_userId_expiryDate_idx" ON "Insurance"("userId", "expiryDate");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_userId_number_key" ON "Vehicle"("userId", "number");

-- CreateIndex
CREATE INDEX "VehicleExpense_vehicleId_date_idx" ON "VehicleExpense"("vehicleId", "date");

-- CreateIndex
CREATE INDEX "Notification_userId_createdAt_idx" ON "Notification"("userId", "createdAt" DESC);

-- CreateIndex
CREATE INDEX "Notification_userId_readAt_idx" ON "Notification"("userId", "readAt");

-- CreateIndex
CREATE INDEX "Notification_userId_date_idx" ON "Notification"("userId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "Notification_userId_dedupeKey_key" ON "Notification"("userId", "dedupeKey");

-- CreateIndex
CREATE INDEX "AiInsight_userId_type_createdAt_idx" ON "AiInsight"("userId", "type", "createdAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "UserWhatsAppLink_phoneE164_key" ON "UserWhatsAppLink"("phoneE164");

-- CreateIndex
CREATE INDEX "UserWhatsAppLink_userId_idx" ON "UserWhatsAppLink"("userId");

-- CreateIndex
CREATE INDEX "WhatsAppInboundMessage_userId_createdAt_idx" ON "WhatsAppInboundMessage"("userId", "createdAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "WhatsAppInboundMessage_provider_providerMessageId_key" ON "WhatsAppInboundMessage"("provider", "providerMessageId");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OTPChallenge" ADD CONSTRAINT "OTPChallenge_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Category" ADD CONSTRAINT "Category_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SubCategory" ADD CONSTRAINT "SubCategory_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_subCategoryId_fkey" FOREIGN KEY ("subCategoryId") REFERENCES "SubCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_recurringExpenseId_fkey" FOREIGN KEY ("recurringExpenseId") REFERENCES "RecurringExpense"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_whatsappMessageId_fkey" FOREIGN KEY ("whatsappMessageId") REFERENCES "WhatsAppInboundMessage"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringExpense" ADD CONSTRAINT "RecurringExpense_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringExpense" ADD CONSTRAINT "RecurringExpense_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Insurance" ADD CONSTRAINT "Insurance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Insurance" ADD CONSTRAINT "Insurance_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VehicleExpense" ADD CONSTRAINT "VehicleExpense_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Document" ADD CONSTRAINT "Document_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AiInsight" ADD CONSTRAINT "AiInsight_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserWhatsAppLink" ADD CONSTRAINT "UserWhatsAppLink_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WhatsAppInboundMessage" ADD CONSTRAINT "WhatsAppInboundMessage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
