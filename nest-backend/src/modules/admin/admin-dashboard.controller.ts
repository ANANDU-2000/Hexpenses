import { Controller, Get, UseGuards } from '@nestjs/common';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminDashboardService } from './admin-dashboard.service';

@Controller('admin/dashboard')
@UseGuards(AdminJwtAuthGuard)
export class AdminDashboardController {
  constructor(private readonly dashboard: AdminDashboardService) {}

  @Get('overview')
  overview() {
    return this.dashboard.overview();
  }

  @Get('analytics')
  analytics() {
    return this.dashboard.analyticsDetail();
  }
}
