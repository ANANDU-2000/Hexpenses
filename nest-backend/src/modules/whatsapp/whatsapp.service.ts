import { ConflictException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { InboundWebhookDto } from './dto/inbound-webhook.dto';
import { UpdateWhatsappPrefsDto } from './dto/update-whatsapp-prefs.dto';
import { WhatsappOutboundService } from './whatsapp-outbound.service';
import { normalizePhoneE164 } from './utils/phone.util';
import * as crypto from 'crypto';

@Injectable()
export class WhatsappService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly outbound: WhatsappOutboundService,
  ) {}

  /**
   * Optional feature: send only if this user has verified this E.164 on WhatsApp.
   * Core product does not require linking; unlinked users get a silent skip (no error to the client beyond skipped status).
   */
  async sendSummary(userId: string, phone: string, text: string) {
    const phoneE164 = normalizePhoneE164(phone);
    const link = await this.prisma.userWhatsAppLink.findFirst({
      where: { userId, phoneE164, verified: true },
    });
    if (!link) {
      return { status: 'skipped' as const, reason: 'whatsapp_not_verified' as const };
    }
    await this.outbound.enqueue(link.phoneE164, text);
    return { status: 'queued' as const };
  }

  /** Inbound message handling (Twilio / Meta); extend with parsing + expense creation when configured. */
  handleInbound(
    dto: InboundWebhookDto | { provider?: string; providerMessageId: string; from: string; body: string },
  ) {
    return {
      ok: true as const,
      received: dto.providerMessageId,
      note: 'Inbound stored stub — configure WhatsApp + workers for full flow.',
    };
  }

  async getStatus(userId: string) {
    const link = await this.prisma.userWhatsAppLink.findFirst({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });
    if (!link) {
      return {
        connected: false,
        verified: false,
        phoneE164: null as string | null,
        dailySummary: true,
        monthlyReport: true,
        alerts: true,
      };
    }
    return {
      connected: link.verified,
      verified: link.verified,
      phoneE164: link.phoneE164,
      dailySummary: link.dailySummary,
      monthlyReport: link.monthlyReport,
      alerts: link.alerts,
    };
  }

  async requestLinkCode(userId: string, phoneE164Raw: string) {
    const phoneE164 = normalizePhoneE164(phoneE164Raw);
    const taken = await this.prisma.userWhatsAppLink.findUnique({ where: { phoneE164 } });
    if (taken && taken.userId !== userId && taken.verified) {
      throw new ConflictException('This WhatsApp number is already linked to another account');
    }
    const code = String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await this.prisma.oTPChallenge.create({
      data: {
        userId,
        mobileNumber: phoneE164,
        code,
        expiresAt,
      },
    });
    const returnCode = this.config.get<string>('WHATSAPP_RETURN_LINK_CODE') === 'true';
    return {
      expiresInSeconds: 600,
      ...(returnCode ? { code } : {}),
      note: returnCode
        ? 'Development: verification code included in JSON. Disable in production.'
        : 'Use the verification code delivered to this number (enable WHATSAPP_RETURN_LINK_CODE=true for local dev).',
    };
  }

  async confirmLinkFromApp(userId: string, phoneE164Raw: string, code: string) {
    const phoneE164 = normalizePhoneE164(phoneE164Raw);
    const row = await this.prisma.oTPChallenge.findFirst({
      where: {
        userId,
        mobileNumber: phoneE164,
        code: code.trim(),
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!row) {
      return { linked: false as const, error: 'invalid_or_expired_code' as const };
    }
    const taken = await this.prisma.userWhatsAppLink.findUnique({ where: { phoneE164 } });
    if (taken && taken.userId !== userId) {
      return { linked: false as const, error: 'phone_linked_to_other_user' as const };
    }
    await this.prisma.$transaction([
      this.prisma.oTPChallenge.update({ where: { id: row.id }, data: { isUsed: true } }),
      this.prisma.userWhatsAppLink.upsert({
        where: { phoneE164 },
        create: { userId, phoneE164, verified: true },
        update: { userId, verified: true },
      }),
    ]);
    return { linked: true as const };
  }

  async updatePreferences(userId: string, dto: UpdateWhatsappPrefsDto) {
    const data: {
      dailySummary?: boolean;
      monthlyReport?: boolean;
      alerts?: boolean;
    } = {};
    if (dto.dailySummary !== undefined) data.dailySummary = dto.dailySummary;
    if (dto.monthlyReport !== undefined) data.monthlyReport = dto.monthlyReport;
    if (dto.alerts !== undefined) data.alerts = dto.alerts;
    if (Object.keys(data).length === 0) {
      return { ok: true as const };
    }
    const where =
      dto.phoneE164 !== undefined
        ? { userId, verified: true, phoneE164: normalizePhoneE164(dto.phoneE164) }
        : { userId, verified: true };
    await this.prisma.userWhatsAppLink.updateMany({ where, data });
    return { ok: true as const };
  }
}
