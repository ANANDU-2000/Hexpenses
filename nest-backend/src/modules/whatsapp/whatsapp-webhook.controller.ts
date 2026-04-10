import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SkipResponseEnvelope } from '../../common/decorators/skip-response-envelope.decorator';
import { InboundWebhookDto } from './dto/inbound-webhook.dto';
import { TwilioSignatureGuard } from './twilio-signature.guard';
import { WhatsappService } from './whatsapp.service';

/**
 * Public webhooks — enable Twilio signature verification in production
 * (TWILIO_AUTH_TOKEN + PUBLIC_WEBHOOK_BASE_URL).
 */
@Controller('whatsapp/webhook')
export class WhatsappWebhookController {
  constructor(
    private readonly whatsapp: WhatsappService,
    private readonly config: ConfigService,
  ) {}

  /** Meta Cloud API verification handshake. */
  @Get('meta')
  @SkipResponseEnvelope()
  metaVerify(
    @Query('hub.mode') mode: string,
    @Query('hub.verify_token') token: string,
    @Query('hub.challenge') challenge: string,
  ) {
    const expected = this.config.get<string>('META_WHATSAPP_VERIFY_TOKEN');
    if (mode === 'subscribe' && expected && token === expected) {
      return challenge;
    }
    throw new ForbiddenException('Verification failed');
  }

  /** Twilio WhatsApp inbound (application/x-www-form-urlencoded). */
  @Post('twilio')
  @UseGuards(TwilioSignatureGuard)
  twilioInbound(@Body() body: Record<string, string>) {
    const from = body.From || '';
    const text = body.Body || '';
    const sid = body.MessageSid || body.SmsSid || '';
    if (!sid) {
      return { ok: false, reason: 'missing_sid' };
    }
    return this.whatsapp.handleInbound({
      provider: 'twilio',
      providerMessageId: sid,
      from,
      body: text || ' ',
    });
  }

  /** Generic JSON bridge (custom integrations, staging). Prefer /twilio in production. */
  @Post('inbound')
  inbound(@Body() dto: InboundWebhookDto) {
    return this.whatsapp.handleInbound(dto);
  }
}
