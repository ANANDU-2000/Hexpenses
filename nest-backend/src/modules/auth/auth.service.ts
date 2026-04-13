import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AppUserStatus, Prisma, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { createHash, createHmac, randomBytes } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { LoginEmailDto } from './dto/login-email.dto';
import { OtpRequestDto, OtpVerifyDto } from './dto/otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

export type SessionMeta = {
  userAgent?: string;
  clientIp?: string;
  deviceLabel?: string;
};

type TokenUser = {
  id: string;
  phone: string | null;
  email: string | null;
  role: UserRole;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  private refreshTokenHashes(raw: string): string[] {
    const pepper = this.config.get<string>('REFRESH_TOKEN_PEPPER')?.trim();
    const hashes: string[] = [];
    if (pepper) {
      hashes.push(createHmac('sha256', pepper).update(raw, 'utf8').digest('hex'));
    }
    hashes.push(createHash('sha256').update(raw, 'utf8').digest('hex'));
    return [...new Set(hashes)];
  }

  private hashIp(ip: string | undefined): string | undefined {
    if (!ip) return undefined;
    const secret =
      this.config.get<string>('REFRESH_TOKEN_PEPPER')?.trim() ||
      this.config.get<string>('JWT_SECRET', 'change-me');
    return createHmac('sha256', secret).update(ip, 'utf8').digest('hex');
  }

  async register(dto: RegisterDto, meta?: SessionMeta) {
    const emailNorm = dto.email?.trim().toLowerCase() ?? null;
    const phoneNorm = dto.phone?.trim() ?? null;
    if (!emailNorm && !phoneNorm) {
      throw new BadRequestException('Provide an email address or a mobile number.');
    }

    const or: Prisma.UserWhereInput[] = [];
    if (emailNorm) or.push({ email: emailNorm });
    if (phoneNorm) or.push({ phone: phoneNorm });
    const existing = await this.prisma.user.findFirst({ where: { OR: or } });
    if (existing) {
      throw new ConflictException('An account with this email or phone already exists.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        name: dto.name.trim(),
        phone: phoneNorm || null,
        email: emailNorm || null,
        passwordHash,
        currency: dto.currency ?? 'INR',
        role: (dto.role as UserRole | undefined) ?? UserRole.owner,
      },
    });
    return this.issueTokenPair(
      { id: user.id, phone: user.phone, email: user.email, role: user.role },
      meta,
    );
  }

  async loginWithEmail(dto: LoginEmailDto, meta?: SessionMeta) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { email, deletedAt: null },
    });
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid email or password.');
    }
    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Invalid email or password.');
    if (user.appUserStatus === AppUserStatus.banned) {
      throw new UnauthorizedException('Account suspended.');
    }
    return this.issueTokenPair(
      { id: user.id, phone: user.phone, email: user.email, role: user.role },
      meta,
    );
  }

  async login(dto: LoginDto, meta?: SessionMeta) {
    const user = await this.prisma.user.findFirst({
      where: { name: dto.username, deletedAt: null },
    });
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid credentials or use OTP login.');
    }
    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Invalid credentials');
    if (user.appUserStatus === AppUserStatus.banned) {
      throw new UnauthorizedException('Account suspended.');
    }
    return this.issueTokenPair(
      { id: user.id, phone: user.phone, email: user.email, role: user.role },
      meta,
    );
  }

  async requestOtp(dto: OtpRequestDto) {
    const code = `${Math.floor(Math.random() * 1000000)}`.padStart(6, '0');
    await this.prisma.oTPChallenge.create({
      data: {
        mobileNumber: dto.mobileNumber,
        code,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });
    return { message: 'OTP sent successfully.', otpCodeForDev: code };
  }

  async verifyOtp(dto: OtpVerifyDto, meta?: SessionMeta) {
    const challenge = await this.prisma.oTPChallenge.findFirst({
      where: {
        mobileNumber: dto.mobileNumber,
        code: dto.otpCode,
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!challenge) throw new UnauthorizedException('Invalid or expired OTP.');
    await this.prisma.oTPChallenge.update({ where: { id: challenge.id }, data: { isUsed: true } });
    let user = await this.prisma.user.findFirst({
      where: { phone: dto.mobileNumber, deletedAt: null },
    });
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          name: `user_${dto.mobileNumber.slice(-8)}`,
          phone: dto.mobileNumber,
          currency: 'INR',
          role: UserRole.owner,
        },
      });
    }
    return this.issueTokenPair(
      { id: user.id, phone: user.phone, email: user.email, role: user.role },
      meta,
    );
  }

  async refreshTokens(dto: RefreshTokenDto, meta?: SessionMeta) {
    const hashes = this.refreshTokenHashes(dto.refreshToken);
    const record = await this.prisma.refreshToken.findFirst({
      where: {
        tokenHash: { in: hashes },
        expiresAt: { gt: new Date() },
      },
      include: { user: true },
    });
    if (!record) {
      throw new UnauthorizedException('Invalid or expired refresh token.');
    }
    if (record.revokedAt) {
      await this.revokeAllRefreshTokensForUser(record.userId);
      throw new UnauthorizedException('Invalid refresh token.');
    }
    if (!record.user || record.user.deletedAt) {
      throw new UnauthorizedException('Invalid or expired refresh token.');
    }

    await this.prisma.refreshToken.update({
      where: { id: record.id },
      data: { revokedAt: new Date(), lastUsedAt: new Date() },
    });

    return this.issueTokenPair(
      {
        id: record.user.id,
        phone: record.user.phone,
        email: record.user.email,
        role: record.user.role,
      },
      {
        ...meta,
        rotatedFromId: record.id,
        deviceLabel: meta?.deviceLabel ?? record.deviceLabel ?? undefined,
      },
    );
  }

  async logout(dto: RefreshTokenDto) {
    const hashes = this.refreshTokenHashes(dto.refreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: { in: hashes }, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  async logoutAll(userId: string) {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  async listSessions(userId: string, currentSessionId?: string) {
    const rows = await this.prisma.refreshToken.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      select: {
        sessionId: true,
        deviceLabel: true,
        userAgent: true,
        createdAt: true,
        lastUsedAt: true,
        lastIpHash: true,
      },
      orderBy: [{ lastUsedAt: 'desc' }, { createdAt: 'desc' }],
    });
    return rows.map((r) => ({
      sessionId: r.sessionId,
      deviceLabel: r.deviceLabel,
      userAgent: r.userAgent,
      createdAt: r.createdAt,
      lastUsedAt: r.lastUsedAt,
      hasIpRecorded: !!r.lastIpHash,
      current: currentSessionId ? r.sessionId === currentSessionId : false,
    }));
  }

  async revokeSession(userId: string, sessionId: string) {
    const res = await this.prisma.refreshToken.updateMany({
      where: { userId, sessionId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (res.count === 0) {
      throw new BadRequestException('Session not found or already revoked.');
    }
    return { ok: true };
  }

  private async revokeAllRefreshTokensForUser(userId: string) {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async issueTokenPair(user: TokenUser, meta?: SessionMeta & { rotatedFromId?: string }) {
    const accessExpires = this.config.get<string>('JWT_ACCESS_EXPIRES_IN', '1h');
    const access = this.jwt.sign(
      {
        sub: user.id,
        phone: user.phone ?? undefined,
        email: user.email ?? undefined,
        role: user.role,
      },
      { expiresIn: accessExpires },
    );
    const rawRefresh = randomBytes(48).toString('base64url');
    const hashes = this.refreshTokenHashes(rawRefresh);
    const tokenHash = hashes[0];
    const days = Number(this.config.get('JWT_REFRESH_EXPIRES_DAYS', 7));
    const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
    const lastIpHash = this.hashIp(meta?.clientIp);
    const row = await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt,
        userAgent: meta?.userAgent,
        deviceLabel: meta?.deviceLabel,
        lastIpHash,
        lastUsedAt: new Date(),
        rotatedFromId: meta?.rotatedFromId,
      },
    });
    return { access, refresh: rawRefresh, sessionId: row.sessionId };
  }
}
