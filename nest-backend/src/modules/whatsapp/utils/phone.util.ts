import { BadRequestException } from '@nestjs/common';

/** Normalize to E.164 with leading + (digits only after +). */
export function normalizePhoneE164(input: string): string {
  const raw = input.replace(/whatsapp:/gi, '').trim();
  if (!raw) throw new BadRequestException('phone is required');
  const digits = raw.replace(/\D/g, '');
  if (digits.length < 8 || digits.length > 15) {
    throw new BadRequestException('phone must be valid E.164 (e.g. +9198xxxxxxx)');
  }
  if (raw.startsWith('+')) return `+${digits}`;
  return `+${digits}`;
}

export function stripToComparableDigits(e164: string): string {
  return e164.replace(/\D/g, '');
}
