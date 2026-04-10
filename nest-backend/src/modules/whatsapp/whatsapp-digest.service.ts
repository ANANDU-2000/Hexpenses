import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CategoryType } from '@prisma/client';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import {
  whatsappDailyDigestRecipientsWhere,
  whatsappMonthlyDigestRecipientsWhere,
} from './whatsapp-link.policy';
import { WhatsappOutboundService } from './whatsapp-outbound.service';

@Injectable()
export class WhatsappDigestService {
  private readonly logger = new Logger(WhatsappDigestService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly outbound: WhatsappOutboundService,
  ) {}

  @Cron('0 0 20 * * *')
  async dailySummariesUtc() {
    if (this.config.get<string>('WHATSAPP_DIGESTS_ENABLED') === 'false') return;
    const links = await this.prisma.userWhatsAppLink.findMany({
      where: whatsappDailyDigestRecipientsWhere(),
      include: { user: true },
    });
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    for (const link of links) {
      try {
        const agg = await this.prisma.expense.aggregate({
          where: {
            userId: link.userId,
            date: { gte: since },
            category: { type: CategoryType.expense },
          },
          _sum: { amount: true },
        });
        const spent = Number(agg._sum.amount ?? 0).toFixed(2);
        const currency = link.user.currency || 'INR';
        const text = `MoneyFlow — Daily summary (last 24h)\nSpent: ${currency} ${spent}`;
        await this.outbound.enqueue(link.phoneE164, text);
      } catch (e) {
        this.logger.warn(`daily digest failed link=${link.id}: ${(e as Error).message}`);
      }
    }
  }

  @Cron('0 30 9 1 * *')
  async monthlyReportUtc() {
    if (this.config.get<string>('WHATSAPP_DIGESTS_ENABLED') === 'false') return;
    const now = new Date();
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
    const monthEnd = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const label = `${monthStart.getUTCFullYear()}-${String(monthStart.getUTCMonth() + 1).padStart(2, '0')}`;

    const links = await this.prisma.userWhatsAppLink.findMany({
      where: whatsappMonthlyDigestRecipientsWhere(),
      include: { user: true },
    });
    for (const link of links) {
      try {
        const agg = await this.prisma.expense.aggregate({
          where: {
            userId: link.userId,
            date: { gte: monthStart, lt: monthEnd },
            category: { type: CategoryType.expense },
          },
          _sum: { amount: true },
        });
        const spent = Number(agg._sum.amount ?? 0).toFixed(2);
        const currency = link.user.currency || 'INR';
        const text = `MoneyFlow — Monthly report (${label})\nTotal spent: ${currency} ${spent}`;
        await this.outbound.enqueue(link.phoneE164, text);
      } catch (e) {
        this.logger.warn(`monthly digest failed link=${link.id}: ${(e as Error).message}`);
      }
    }
  }
}
