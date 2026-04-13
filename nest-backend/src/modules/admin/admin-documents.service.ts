import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminActivityService } from './admin-activity.service';

@Injectable()
export class AdminDocumentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activity: AdminActivityService,
  ) {}

  async list(q: { userId?: string; type?: string; skip?: number; take?: number }) {
    const where: Prisma.DocumentWhereInput = {};
    if (q.userId) where.userId = q.userId;
    if (q.type?.trim()) where.type = { equals: q.type.trim(), mode: 'insensitive' };
    const [rows, total] = await Promise.all([
      this.prisma.document.findMany({
        where,
        skip: q.skip ?? 0,
        take: Math.min(q.take ?? 50, 150),
        orderBy: { uploadedAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, email: true } },
        },
      }),
      this.prisma.document.count({ where }),
    ]);
    return { rows, total };
  }

  async remove(adminId: string, id: string) {
    const doc = await this.prisma.document.findFirst({ where: { id } });
    if (!doc) throw new NotFoundException('Document not found');
    await this.prisma.document.delete({ where: { id } });
    await this.activity.log(adminId, 'document.delete', { id });
    return { ok: true };
  }
}
