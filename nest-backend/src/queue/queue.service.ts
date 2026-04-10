import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationCategory } from '@prisma/client';
import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

export type NotificationJobPayload = {
  userId: string;
  title: string;
  category: NotificationCategory;
  body?: string;
  dedupeKey?: string;
};

export type AiInsightsJobPayload = {
  userId: string;
};

@Injectable()
export class QueueService implements OnModuleInit {
  private readonly logger = new Logger(QueueService.name);
  private connection: IORedis | undefined;

  /** When false, use inline fallbacks (no BullMQ workers). */
  redisAvailable = false;

  recurringQueue?: Queue;
  notificationQueue?: Queue;
  /** Outbound WhatsApp text (Twilio / Meta); separate from notifications worker payload. */
  whatsappOutboundQueue?: Queue;
  /** Background financial insight generation (AiService.analyzeUserFinancialData). */
  aiInsightsQueue?: Queue;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit() {
    const disabled = this.config.get<string>('REDIS_DISABLED', '') === 'true';
    if (disabled) {
      this.logger.warn('REDIS_DISABLED=true: skipping Redis; recurring/notifications use inline paths where supported');
      return;
    }
    const redisUrl = this.config.get<string>('REDIS_URL', 'redis://localhost:6379');
    let conn: IORedis | undefined;
    try {
      conn = new IORedis(redisUrl, {
        maxRetriesPerRequest: null,
        lazyConnect: true,
        connectTimeout: 8000,
        retryStrategy: () => null,
      });
      conn.on('error', () => {
        /* Avoid process "Unhandled error event"; failures surface via connect/ping */
      });
      await conn.connect();
      await conn.ping();
      this.connection = conn;
      this.redisAvailable = true;
      this.recurringQueue = new Queue('recurring', { connection: conn });
      this.notificationQueue = new Queue('notifications', { connection: conn });
      this.whatsappOutboundQueue = new Queue('whatsapp-outbound', { connection: conn });
      this.aiInsightsQueue = new Queue('ai-insights', { connection: conn });
      this.logger.log('Redis connected; BullMQ queues ready');
    } catch (e) {
      if (conn) {
        conn.removeAllListeners('error');
        await conn.quit().catch(() => undefined);
      }
      this.logger.warn(
        `Redis unavailable (${(e as Error).message}). Start Redis or set REDIS_DISABLED=true. Using inline fallbacks.`,
      );
    }
  }

  createRecurringWorker(handler: (job: { data: { recurringId: string } }) => Promise<void>) {
    if (!this.connection || !this.redisAvailable) return undefined;
    return new Worker('recurring', handler, { connection: this.connection });
  }

  createNotificationWorker(handler: (job: { data: NotificationJobPayload }) => Promise<void>) {
    if (!this.connection || !this.redisAvailable) return undefined;
    return new Worker('notifications', handler, {
      connection: this.connection,
      concurrency: 5,
    });
  }

  createWhatsappOutboundWorker(
    handler: (job: { data: { to: string; body: string } }) => Promise<void>,
  ) {
    if (!this.connection || !this.redisAvailable) return undefined;
    return new Worker('whatsapp-outbound', handler, {
      connection: this.connection,
      concurrency: 3,
    });
  }

  createAiInsightsWorker(handler: (job: { data: AiInsightsJobPayload }) => Promise<void>) {
    if (!this.connection || !this.redisAvailable) return undefined;
    return new Worker('ai-insights', handler, {
      connection: this.connection,
      concurrency: 2,
    });
  }

  /** Enqueue insight analysis; returns false if Redis queue is unavailable. */
  async enqueueAiInsightsJob(userId: string): Promise<boolean> {
    if (!this.aiInsightsQueue) return false;
    await this.aiInsightsQueue.add(
      'analyze',
      { userId } satisfies AiInsightsJobPayload,
      { removeOnComplete: 100, removeOnFail: 50, attempts: 2, backoff: { type: 'exponential', delay: 5000 } },
    );
    return true;
  }
}
