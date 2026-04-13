import { Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminNotificationsService } from './admin-notifications.service';
import { AdminSendNotificationDto } from './dto/admin-send-notification.dto';
import { AdminRequestUser } from './types/admin-request-user';

@Controller('admin/notifications')
@UseGuards(AdminJwtAuthGuard)
export class AdminNotificationsController {
  constructor(private readonly notifications: AdminNotificationsService) {}

  @Get()
  list(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.notifications.list(
      skip ? parseInt(skip, 10) : 0,
      take ? parseInt(take, 10) : 50,
    );
  }

  @Post('send')
  send(
    @Req() req: Request & { user: AdminRequestUser },
    @Body() body: AdminSendNotificationDto,
  ) {
    return this.notifications.send(req.user.adminId, body);
  }
}
