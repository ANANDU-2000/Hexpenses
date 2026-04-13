import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminSettingsService } from './admin-settings.service';
import { AdminUpsertSettingDto } from './dto/admin-setting.dto';
import { AdminRequestUser } from './types/admin-request-user';

@Controller('admin/settings')
@UseGuards(AdminJwtAuthGuard)
export class AdminSettingsController {
  constructor(private readonly settings: AdminSettingsService) {}

  @Get()
  getAll() {
    return this.settings.getAll();
  }

  @Post()
  upsert(
    @Req() req: Request & { user: AdminRequestUser },
    @Body() body: AdminUpsertSettingDto,
  ) {
    return this.settings.upsert(req.user.adminId, body);
  }
}
