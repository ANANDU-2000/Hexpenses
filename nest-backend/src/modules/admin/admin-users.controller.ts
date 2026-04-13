import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { AppUserStatus } from '@prisma/client';
import { Request } from 'express';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminUsersService } from './admin-users.service';
import { AdminUserStatusDto } from './dto/admin-user-status.dto';
import { AdminRequestUser } from './types/admin-request-user';

@Controller('admin/users')
@UseGuards(AdminJwtAuthGuard)
export class AdminUsersController {
  constructor(private readonly users: AdminUsersService) {}

  @Get()
  list(
    @Query('search') search?: string,
    @Query('status') status?: AppUserStatus,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.users.list({
      search,
      status,
      skip: skip ? parseInt(skip, 10) : undefined,
      take: take ? parseInt(take, 10) : undefined,
    });
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.users.detail(id);
  }

  @Patch(':id/status')
  setStatus(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
    @Body() body: AdminUserStatusDto,
  ) {
    return this.users.setStatus(req.user.adminId, id, body.status);
  }

  @Delete(':id')
  remove(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
  ) {
    return this.users.remove(req.user.adminId, id);
  }
}
