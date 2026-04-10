import { Prisma } from '@prisma/client';

/**
 * WhatsApp is optional. Core APIs and login must never require a link.
 * Outbound WhatsApp (digests, budget alerts) must only run when the user has
 * a verified link — equivalent to checking `user.userWhatsAppLinks.some(l => l.verified)`.
 */
export const verifiedWhatsappLinkWhere = (
  userId: string,
  extra?: Pick<Prisma.UserWhatsAppLinkWhereInput, 'alerts' | 'dailySummary' | 'monthlyReport'>,
): Prisma.UserWhatsAppLinkWhereInput => ({
  userId,
  verified: true,
  ...extra,
});

/** Cron / batch: users who should receive daily WhatsApp summaries (requires verified link). */
export const whatsappDailyDigestRecipientsWhere = (): Prisma.UserWhatsAppLinkWhereInput => ({
  verified: true,
  dailySummary: true,
});

/** Cron / batch: users who should receive monthly WhatsApp reports (requires verified link). */
export const whatsappMonthlyDigestRecipientsWhere = (): Prisma.UserWhatsAppLinkWhereInput => ({
  verified: true,
  monthlyReport: true,
});
