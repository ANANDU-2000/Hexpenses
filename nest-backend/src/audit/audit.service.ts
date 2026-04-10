import { Injectable } from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { AuditEntity } from './audit.types';

export type AuditLogPayload = {
  userId: string;
  action: AuditAction;
  entity: AuditEntity;
  entityId: string;
  metadata?: Prisma.InputJsonValue;
};

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  /** Fire-and-forget; failures must not break primary requests. */
  logAction(payload: AuditLogPayload): void {
    void this.prisma.auditLog
      .create({
        data: {
          id: randomUUID(),
          userId: payload.userId,
          action: payload.action,
          entity: payload.entity,
          entityId: payload.entityId,
          metadata: payload.metadata ?? undefined,
        },
      })
      .catch(() => undefined);
  }
}
