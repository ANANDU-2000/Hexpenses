import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { Document, Prisma } from '@prisma/client';
import { createReadStream, existsSync, mkdirSync } from 'fs';
import type { Express } from 'express';
import { join } from 'path';
import { PrismaService } from '../../prisma/prisma.service';
import { ListDocumentsDto } from './dto/list-documents.dto';

const UPLOAD_SUBDIR = 'uploads';

@Injectable()
export class DocumentsService implements OnModuleInit {
  constructor(private readonly prisma: PrismaService) {}

  onModuleInit() {
    const dir = this.uploadsDir();
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  }

  uploadsDir(): string {
    return join(process.cwd(), UPLOAD_SUBDIR);
  }

  private parseTags(tags?: string): string[] {
    if (!tags?.trim()) return [];
    return [
      ...new Set(
        tags
          .split(/[,;]+/)
          .map((t) => t.trim().toLowerCase())
          .filter(Boolean),
      ),
    ];
  }

  private buildSearchBlob(originalName: string | null, type: string, tags: string[]): string {
    return [originalName ?? '', type, ...tags].join(' ').toLowerCase();
  }

  async createFromUpload(
    userId: string,
    file: Express.Multer.File,
    type: string,
    tagsRaw?: string,
    expenseId?: string,
  ): Promise<Document> {
    const tags = this.parseTags(tagsRaw);
    if (expenseId) {
      const exp = await this.prisma.expense.findFirst({
        where: { id: expenseId, userId },
      });
      if (!exp) throw new BadRequestException('Expense not found');
    }
    const searchBlob = this.buildSearchBlob(file.originalname ?? null, type, tags);
    return this.prisma.document.create({
      data: {
        userId,
        fileUrl: file.filename,
        type,
        originalName: file.originalname,
        mimeType: file.mimetype,
        tags,
        searchBlob,
        expenseId: expenseId ?? undefined,
      },
    });
  }

  async list(userId: string, query: ListDocumentsDto): Promise<Document[]> {
    const where: Prisma.DocumentWhereInput = { userId };
    if (query.type) where.type = query.type;
    if (query.expenseId) where.expenseId = query.expenseId;
    if (query.tag?.trim()) where.tags = { has: query.tag.trim().toLowerCase() };
    if (query.q?.trim()) {
      where.searchBlob = { contains: query.q.trim().toLowerCase() };
    }
    const take = query.limit ?? 200;
    return this.prisma.document.findMany({
      where,
      orderBy: { uploadedAt: 'desc' },
      take,
    });
  }

  async updateTags(userId: string, id: string, tags: string[]): Promise<Document> {
    const normalized = [...new Set(tags.map((t) => t.trim().toLowerCase()).filter(Boolean))];
    const row = await this.prisma.document.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Document not found');
    const searchBlob = this.buildSearchBlob(row.originalName, row.type, normalized);
    return this.prisma.document.update({
      where: { id },
      data: { tags: normalized, searchBlob },
    });
  }

  async openFileStream(userId: string, id: string) {
    const row = await this.prisma.document.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Document not found');
    const full = join(this.uploadsDir(), row.fileUrl);
    if (!existsSync(full)) throw new NotFoundException('File missing on server');
    return {
      stream: createReadStream(full),
      mime: row.mimeType || 'application/octet-stream',
      downloadName: row.originalName || row.fileUrl,
    };
  }
}
