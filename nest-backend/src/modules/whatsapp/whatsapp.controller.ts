import { Body, Controller, Get, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { LinkConfirmDto } from './dto/link-confirm.dto';
import { LinkRequestDto } from './dto/link-request.dto';
import { UpdateWhatsappPrefsDto } from './dto/update-whatsapp-prefs.dto';
import { WhatsappService } from './whatsapp.service';

@Controller('whatsapp')
@UseGuards(JwtAuthGuard)
export class WhatsappController {
  constructor(private readonly whatsapp: WhatsappService) {}

  /** Linking is optional; use for settings UI (no errors if omitted). */
  @Get('status')
  status(@Req() req: { user: { userId: string } }) {
    return this.whatsapp.getStatus(req.user.userId);
  }

  @Post('summary')
  summary(@Req() req: { user: { userId: string } }, @Body() body: { phone: string; text: string }) {
    return this.whatsapp.sendSummary(req.user.userId, body.phone, body.text);
  }

  /** @deprecated Use `POST /whatsapp/link` — kept for older clients */
  @Post('link/request')
  linkRequest(@Req() req: { user: { userId: string } }, @Body() dto: LinkRequestDto) {
    return this.whatsapp.requestLinkCode(req.user.userId, dto.phoneE164);
  }

  /** @deprecated Use `POST /whatsapp/verify` — kept for older clients */
  @Post('link/confirm')
  linkConfirm(@Req() req: { user: { userId: string } }, @Body() dto: LinkConfirmDto) {
    return this.whatsapp.confirmLinkFromApp(req.user.userId, dto.phoneE164, dto.code);
  }

  /** Request a verification code for this E.164 (same as `link/request`). */
  @Post('link')
  link(@Req() req: { user: { userId: string } }, @Body() dto: LinkRequestDto) {
    return this.whatsapp.requestLinkCode(req.user.userId, dto.phoneE164);
  }

  /** Confirm linking with the 6-digit code (same as `link/confirm`). */
  @Post('verify')
  verify(@Req() req: { user: { userId: string } }, @Body() dto: LinkConfirmDto) {
    return this.whatsapp.confirmLinkFromApp(req.user.userId, dto.phoneE164, dto.code);
  }

  @Patch('preferences')
  preferences(@Req() req: { user: { userId: string } }, @Body() dto: UpdateWhatsappPrefsDto) {
    return this.whatsapp.updatePreferences(req.user.userId, dto);
  }
}
