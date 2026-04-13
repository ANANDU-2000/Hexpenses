import { Injectable } from '@nestjs/common';
import { NotificationChannel } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminActivityService } from './admin-activity.service';
import {
  AdminSendNotificationDto,
  mapAdminNotifCategory,
} from './dto/admin-send-notification.dto';

@Injectable()
export class AdminNotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activity: AdminActivityService,
  ) {}

  async send(adminId: string, dto: AdminSendNotificationDto) {
    const category = mapAdminNotifCategory(dto.type);
    const now = new Date();

    let userIds: string[];
    if (dto.userIds?.length) {
      userIds = dto.userIds;
    } else {
      const users = await this.prisma.user.findMany({
        where: { deletedAt: null },
        select: { id: true },
      });
      userIds = users.map((u) => u.id);
    }

    const data = userIds.map((userId) => ({
      title: dto.title,
      body: dto.message,
      userId,
      date: now,
      channel: NotificationChannel.in_app,
      category,
    }));

    await this.prisma.notification.createMany({ data });
    await this.activity.log(adminId, 'notification.broadcast', {
      count: data.length,
      type: dto.type,
    });
    return { sent: data.length };
  }

  async list(skip = 0, take = 50) {
    const [rows, total] = await Promise.all([
      this.prisma.notification.findMany({
        skip,
        take: Math.min(take, 100),
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, email: true } },
        },
      }),
      this.prisma.notification.count(),
    ]);
    return { rows, total };
  }
}
