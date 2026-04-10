import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'crypto';

const PREFIX = 'enc:v1:';

@Injectable()
export class FieldEncryptionService {
  private readonly log = new Logger(FieldEncryptionService.name);

  constructor(private readonly config: ConfigService) {
    const key = this.resolveKey();
    if (!key) {
      this.log.warn(
        'FIELD_ENCRYPTION_KEY is not set; sensitive fields are stored in plaintext. Set a 32-byte key (64 hex chars or base64) for production.',
      );
    }
  }

  private resolveKey(): Buffer | null {
    const raw = this.config.get<string>('FIELD_ENCRYPTION_KEY')?.trim();
    if (!raw) return null;
    if (/^[0-9a-fA-F]{64}$/.test(raw)) {
      return Buffer.from(raw, 'hex');
    }
    try {
      const buf = Buffer.from(raw, 'base64');
      if (buf.length === 32) return buf;
    } catch {
      /* fall through */
    }
    return createHash('sha256').update(raw, 'utf8').digest();
  }

  encrypt(plain: string | null | undefined): string | null {
    if (plain == null || plain === '') return plain ?? null;
    const key = this.resolveKey();
    if (!key) return plain;
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    const enc = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return `${PREFIX}${iv.toString('base64url')}.${tag.toString('base64url')}.${enc.toString('base64url')}`;
  }

  decrypt(stored: string | null | undefined): string | null {
    if (stored == null || stored === '') return stored ?? null;
    if (!stored.startsWith(PREFIX)) return stored;
    const key = this.resolveKey();
    if (!key) {
      throw new Error('FIELD_ENCRYPTION_KEY required to decrypt stored values.');
    }
    const payload = stored.slice(PREFIX.length);
    const [ivB64, tagB64, dataB64] = payload.split('.');
    if (!ivB64 || !tagB64 || !dataB64) throw new Error('Invalid encrypted field format.');
    const iv = Buffer.from(ivB64, 'base64url');
    const tag = Buffer.from(tagB64, 'base64url');
    const data = Buffer.from(dataB64, 'base64url');
    const decipher = createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
  }
}
