import {
  forwardRef,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { NotificationCategory, NotificationChannel, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationJobPayload, QueueService } from '../../queue/queue.service';
import { WhatsappOutboundService } from '../whatsapp/whatsapp-outbound.service';
import { ListNotificationsDto } from './dto/list-notifications.dto';

export interface EnqueueNotificationPayload extends NotificationJobPayload {
  channel?: NotificationChannel;
}

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly queue: QueueService,
    @Inject(forwardRef(() => WhatsappOutboundService))
    private readonly whatsappOutbound: WhatsappOutboundService,
  ) {}

  onModuleInit() {
    this.queue.createNotificationWorker(async (job) => {
      const payload = job.data as EnqueueNotificationPayload;
      await this.persistNotification(payload);
    });
    if (!this.queue.redisAvailable) {
      this.logger.warn('Notification worker not started (no Redis); notifications are stored inline when created');
    }
  }

  private async persistNotification(payload: EnqueueNotificationPayload) {
    try {
      const row = await this.prisma.notification.create({
        data: {
          userId: payload.userId,
          title: payload.title,
          body: payload.body,
          category: payload.category,
          channel: payload.channel ?? NotificationChannel.in_app,
          date: new Date(),
          dedupeKey: payload.dedupeKey,
        },
      });
      void this.whatsappOutbound
        .notifyAlertIfEnabled(payload.userId, payload.title, payload.body ?? '')
        .catch((e) => this.logger.warn(`WhatsApp alert forward: ${(e as Error).message}`));
      return row;
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        return null;
      }
      throw e;
    }
  }

  list(userId: string, query: ListNotificationsDto) {
    const where: Prisma.NotificationWhereInput = { userId };
    if (query.category) where.category = query.category;
    if (query.unreadOnly === true) where.readAt = null;
    const take = query.limit ?? 100;
    return this.prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take,
    });
  }

  async markRead(userId: string, id: string) {
    const row = await this.prisma.notification.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Notification not found');
    return this.prisma.notification.update({
      where: { id },
      data: { readAt: new Date() },
    });
  }

  async markAllRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: true };
  }

  async create(
    userId: string,
    title: string,
    category: NotificationCategory,
    options?: { body?: string; dedupeKey?: string },
  ) {
    const payload: EnqueueNotificationPayload = {
      userId,
      title,
      category,
      body: options?.body,
      dedupeKey: options?.dedupeKey,
    };
    if (!this.queue.notificationQueue) {
      return this.persistNotification(payload);
    }
    return this.queue.notificationQueue.add('store-notification', payload, {
      jobId: options?.dedupeKey ?? `notification-${userId}-${category}-${Date.now()}`,
      attempts: 3,
      backoff: { type: 'fixed', delay: 3000 },
    });
  }
}
