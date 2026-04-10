import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { PrismaService } from '../../prisma/prisma.service';
import { QueueService } from '../../queue/queue.service';
import { normalizePhoneE164 } from './utils/phone.util';

@Injectable()
export class WhatsappOutboundService implements OnModuleInit {
  private readonly logger = new Logger(WhatsappOutboundService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly queue: QueueService,
    private readonly prisma: PrismaService,
  ) {}

  onModuleInit() {
    this.queue.createWhatsappOutboundWorker(async (job) => {
      const { to, body } = job.data as { to: string; body: string };
      await this.sendTextDirect(to, body);
    });
    if (!this.queue.redisAvailable) {
      this.logger.warn('WhatsApp outbound queue disabled (no Redis); sends run inline');
    }
  }

  /** Queue when Redis available, otherwise send immediately. */
  async enqueue(toE164: string, body: string): Promise<void> {
    const to = normalizePhoneE164(toE164);
    if (this.queue.whatsappOutboundQueue) {
      await this.queue.whatsappOutboundQueue.add(
        'send',
        { to, body },
        { attempts: 4, backoff: { type: 'exponential', delay: 5000 } },
      );
      return;
    }
    await this.sendTextDirect(to, body);
  }

  async sendTextDirect(toE164: string, body: string): Promise<void> {
    if (this.config.get<string>('WHATSAPP_ENABLED') === 'false') {
      this.logger.debug('WHATSAPP_ENABLED=false; skip send');
      return;
    }
    const sid = this.config.get<string>('TWILIO_ACCOUNT_SID');
    const token = this.config.get<string>('TWILIO_AUTH_TOKEN');
    const from = this.config.get<string>('TWILIO_WHATSAPP_FROM');
    if (!sid || !token || !from) {
      this.logger.warn('Twilio WhatsApp not configured (TWILIO_* env); message not sent');
      return;
    }
    const toAddr = toE164.startsWith('whatsapp:') ? toE164 : `whatsapp:${toE164}`;
    const auth = Buffer.from(`${sid}:${token}`).toString('base64');
    const params = new URLSearchParams({ From: from, To: toAddr, Body: body });
    const res = await axios.post(
      `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
      params.toString(),
      {
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        timeout: 20_000,
      },
    );
    if (res.status >= 300) {
      throw new Error(`Twilio HTTP ${res.status}`);
    }
  }

  /**
   * Whether the user has at least one verified WhatsApp link (optional product feature).
   * Use before any outbound WhatsApp-specific action, e.g. `if (await hasVerifiedWhatsapp(userId)) { ... }`
   */
  async hasVerifiedWhatsapp(userId: string): Promise<boolean> {
    const n = await this.prisma.userWhatsAppLink.count({
      where: { userId, verified: true },
    });
    return n > 0;
  }

  /** Verified link with alerts enabled (budget / system notifications on WhatsApp). */
  async hasVerifiedWhatsappForAlerts(userId: string): Promise<boolean> {
    const n = await this.prisma.userWhatsAppLink.count({
      where: { userId, verified: true, alerts: true },
    });
    return n > 0;
  }

  /** Forward app notifications as WhatsApp text only when linked, verified, and alerts enabled. */
  async notifyAlertIfEnabled(userId: string, title: string, body: string): Promise<void> {
    if (this.config.get<string>('WHATSAPP_ENABLED') === 'false') return;
    const links = await this.prisma.userWhatsAppLink.findMany({
      where: { userId, verified: true, alerts: true },
    });
    if (links.length === 0) return;
    const text = body?.trim() ? `${title}\n${body}` : title;
    for (const link of links) {
      try {
        await this.enqueue(link.phoneE164, text.slice(0, 1500));
      } catch (e) {
        this.logger.warn(`WhatsApp alert failed user=${userId}: ${(e as Error).message}`);
      }
    }
  }
}
