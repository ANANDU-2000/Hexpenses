import { Body, Controller, Delete, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { UsersService } from '../users/users.service';
import { AuthService, SessionMeta } from './auth.service';
import { LoginEmailDto } from './dto/login-email.dto';
import { LoginDto } from './dto/login.dto';
import { OtpRequestDto, OtpVerifyDto } from './dto/otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

function sessionMeta(req: Request): SessionMeta {
  const ua = typeof req.headers['user-agent'] === 'string' ? req.headers['user-agent'] : undefined;
  const rawDevice = req.headers['x-device-name'];
  const deviceLabel =
    typeof rawDevice === 'string' ? rawDevice.trim().slice(0, 120) : undefined;
  const xf = req.headers['x-forwarded-for'];
  const first = typeof xf === 'string' ? xf.split(',')[0].trim() : undefined;
  const clientIp = first || req.ip || req.socket?.remoteAddress;
  return { userAgent: ua, clientIp, deviceLabel: deviceLabel || undefined };
}

function currentSessionId(req: Request): string | undefined {
  const h = req.headers['x-session-id'];
  return typeof h === 'string' ? h.trim() : undefined;
}

@Controller()
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  /** Legacy: sign in with display name + password (not email). */
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('login')
  login(@Body() dto: LoginDto, @Req() req: Request) {
    return this.authService.login(dto, sessionMeta(req));
  }

  /** Sign in with email + password (primary for the mobile/web app). */
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('auth/login')
  loginWithEmail(@Body() dto: LoginEmailDto, @Req() req: Request) {
    return this.authService.loginWithEmail(dto, sessionMeta(req));
  }

  /** @deprecated Use POST /auth/login */
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('auth/login/email')
  loginWithEmailLegacy(@Body() dto: LoginEmailDto, @Req() req: Request) {
    return this.authService.loginWithEmail(dto, sessionMeta(req));
  }

  /** Create account; returns access + refresh tokens. */
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('auth/register')
  registerAuth(@Body() dto: RegisterDto, @Req() req: Request) {
    return this.authService.register(dto, sessionMeta(req));
  }

  /** @deprecated Use POST /auth/register */
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('register')
  register(@Body() dto: RegisterDto, @Req() req: Request) {
    return this.authService.register(dto, sessionMeta(req));
  }

  @Throttle({ default: { limit: 45, ttl: 60_000 } })
  @Post('token/refresh')
  refresh(@Body() dto: RefreshTokenDto, @Req() req: Request) {
    return this.authService.refreshTokens(dto, sessionMeta(req));
  }

  @Post('auth/logout')
  logout(@Body() dto: RefreshTokenDto) {
    return this.authService.logout(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('auth/logout-all')
  logoutAll(@Req() req: { user: { userId: string } }) {
    return this.authService.logoutAll(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('auth/sessions')
  listSessions(@Req() req: Request & { user: { userId: string } }) {
    return this.authService.listSessions(req.user.userId, currentSessionId(req));
  }

  @UseGuards(JwtAuthGuard)
  @Delete('auth/sessions/:sessionId')
  revokeSession(
    @Req() req: { user: { userId: string } },
    @Param('sessionId') sessionId: string,
  ) {
    return this.authService.revokeSession(req.user.userId, sessionId);
  }

  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  @Post('auth/otp/request')
  requestOtp(@Body() dto: OtpRequestDto) {
    return this.authService.requestOtp(dto);
  }

  @Throttle({ default: { limit: 15, ttl: 60_000 } })
  @Post('auth/otp/verify')
  verifyOtp(@Body() dto: OtpVerifyDto, @Req() req: Request) {
    return this.authService.verifyOtp(dto, sessionMeta(req));
  }

  /** @deprecated Prefer GET /api/users/me */
  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: { user: { userId: string } }) {
    return this.usersService.getPublicProfile(req.user.userId);
  }
}
