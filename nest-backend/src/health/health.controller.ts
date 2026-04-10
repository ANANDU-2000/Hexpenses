import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { PrismaService } from '../prisma/prisma.service';

@SkipThrottle()
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async get() {
    if (this.prisma.databaseDisabled) {
      return { status: 'ok', database: 'disabled' as const };
    }
    try {
      await this.prisma.$queryRawUnsafe('SELECT 1');
      return { status: 'ok', database: 'connected' as const };
    } catch {
      return { status: 'ok', database: 'unreachable' as const };
    }
  }
}
