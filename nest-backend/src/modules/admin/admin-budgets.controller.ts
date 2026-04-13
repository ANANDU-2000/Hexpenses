import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminBudgetsService } from './admin-budgets.service';

@Controller('admin/budgets')
@UseGuards(AdminJwtAuthGuard)
export class AdminBudgetsController {
  constructor(private readonly budgets: AdminBudgetsService) {}

  @Get()
  list(@Query('userId') userId?: string) {
    return this.budgets.listWithOverspend(userId);
  }
}
