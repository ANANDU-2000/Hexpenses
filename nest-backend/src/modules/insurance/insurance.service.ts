import { Injectable } from '@nestjs/common';
import { NotificationCategory } from '@prisma/client';
import { Cron, CronExpression } from '@nestjs/schedule';
import { FieldEncryptionService } from '../../crypto/field-encryption.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class InsuranceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly fieldCrypto: FieldEncryptionService,
  ) {}

  async list(userId: string) {
    const rows = await this.prisma.insurance.findMany({
      where: { userId },
      orderBy: { expiryDate: 'asc' },
    });
    return rows.map((r) => ({
      ...r,
      policyNumber: this.fieldCrypto.decrypt(r.policyNumber) ?? r.policyNumber,
    }));
  }

  async create(userId: string, body: any) {
    const row = await this.prisma.insurance.create({
      data: {
        userId,
        name: body.name,
        type: body.type,
        premium: body.premium,
        startDate: new Date(body.startDate),
        expiryDate: new Date(body.expiryDate),
        provider: body.provider,
        policyNumber: this.fieldCrypto.encrypt(body.policyNumber),
        reminderDaysBefore: body.reminderDaysBefore ?? 7,
      },
    });
    return {
      ...row,
      policyNumber: this.fieldCrypto.decrypt(row.policyNumber) ?? row.policyNumber,
    };
  }

  @Cron(CronExpression.EVERY_DAY_AT_1AM)
  async notifyExpiring() {
    if (this.prisma.databaseDisabled) return;
    const threshold = new Date();
    threshold.setDate(threshold.getDate() + 3);
    const expiring = await this.prisma.insurance.findMany({
      where: { expiryDate: { lte: threshold } },
    });
    for (const row of expiring) {
      const dedupeKey = `insurance-expiry-${row.id}-${row.expiryDate.toISOString().slice(0, 10)}`;
      await this.notifications.create(row.userId, `Insurance ${row.name} expires soon`, NotificationCategory.insurance, {
        body: `Expires on ${row.expiryDate.toISOString().slice(0, 10)}`,
        dedupeKey,
      });
    }
  }
}
