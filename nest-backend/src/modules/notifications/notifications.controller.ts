import { Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  async list(@Req() req: { user: { userId: string } }, @Query() query: ListNotificationsDto) {
    const rows = await this.notifications.list(req.user.userId, query);
    return { notifications: rows };
  }

  @Post('mark-all-read')
  markAllRead(@Req() req: { user: { userId: string } }) {
    return this.notifications.markAllRead(req.user.userId);
  }

  @Patch(':id/read')
  markRead(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.notifications.markRead(req.user.userId, id);
  }
}
