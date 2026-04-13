import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminActivityService {
  constructor(private readonly prisma: PrismaService) {}

  log(adminId: string, action: string, metadata?: Prisma.InputJsonValue) {
    return this.prisma.adminActivityLog.create({
      data: { adminId, action, metadata },
    });
  }
}
