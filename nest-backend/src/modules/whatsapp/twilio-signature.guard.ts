import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';
import twilio from 'twilio';

@Injectable()
export class TwilioSignatureGuard implements CanActivate {
  private readonly logger = new Logger(TwilioSignatureGuard.name);

  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    if (this.config.get<string>('WHATSAPP_WEBHOOK_SKIP_VERIFY') === 'true') {
      return true;
    }
    const authToken = this.config.get<string>('TWILIO_AUTH_TOKEN');
    const base = this.config.get<string>('PUBLIC_WEBHOOK_BASE_URL');
    if (!authToken || !base) {
      this.logger.warn('Twilio webhook verify enabled but TWILIO_AUTH_TOKEN or PUBLIC_WEBHOOK_BASE_URL missing');
      throw new ForbiddenException('Webhook not configured');
    }
    const req = context.switchToHttp().getRequest<Request>();
    const signature = req.headers['x-twilio-signature'];
    if (!signature || typeof signature !== 'string') {
      throw new ForbiddenException('Missing X-Twilio-Signature');
    }
    const url = `${base.replace(/\/$/, '')}/whatsapp/webhook/twilio`;
    const params = (req.body ?? {}) as Record<string, string>;
    const ok = twilio.validateRequest(authToken, signature, url, params);
    if (!ok) {
      throw new ForbiddenException('Invalid Twilio signature');
    }
    return true;
  }
}
