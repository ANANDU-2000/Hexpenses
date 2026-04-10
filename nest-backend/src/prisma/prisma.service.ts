import { INestApplication, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  private readonly logger = new Logger(PrismaService.name);

  /** When true, `$connect` is skipped so the API can boot without a working Postgres. DB calls will still fail until disabled. */
  readonly databaseDisabled: boolean;

  constructor(private readonly config: ConfigService) {
    super();
    this.databaseDisabled =
      this.config.get<string>('DATABASE_DISABLED', '').toLowerCase() === 'true';
  }

  async onModuleInit() {
    if (this.databaseDisabled) {
      this.logger.warn(
        'DATABASE_DISABLED=true: not connecting to Postgres. Set DATABASE_DISABLED=false and a valid DATABASE_URL for real data.',
      );
      return;
    }
    await this.$connect();
  }

  async enableShutdownHooks(app: INestApplication) {
    if (this.databaseDisabled) return;
    this.$on('beforeExit' as never, async () => {
      await app.close();
    });
  }
}
