-- AlterTable
ALTER TABLE "Document" ADD COLUMN     "originalName" TEXT,
ADD COLUMN "mimeType" TEXT,
ADD COLUMN "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "searchBlob" TEXT NOT NULL DEFAULT '';

-- Backfill search text from existing rows
UPDATE "Document" SET "searchBlob" = lower(
  COALESCE("type", '') || ' ' || COALESCE("fileUrl", '')
);

-- Normalize legacy fileUrl to file name only (strip path prefix)
UPDATE "Document" SET "fileUrl" = regexp_replace("fileUrl", '^.*[/\\\\]', '') WHERE "fileUrl" ~ '[/\\\\]';

CREATE INDEX "Document_userId_uploadedAt_idx" ON "Document"("userId", "uploadedAt" DESC);
