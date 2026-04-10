import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { VehiclesService } from './vehicles.service';

@Controller('vehicles')
@UseGuards(JwtAuthGuard)
export class VehiclesController {
  constructor(private readonly vehicles: VehiclesService) {}

  @Get()
  list(@Req() req: { user: { userId: string } }) {
    return this.vehicles.list(req.user.userId);
  }

  @Post()
  create(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.vehicles.create(req.user.userId, body);
  }

  @Post(':id/costs')
  addExpense(@Param('id') id: string, @Body() body: any) {
    return this.vehicles.addExpense(id, body);
  }

  @Get(':id/total-cost')
  totalCost(@Param('id') id: string) {
    return this.vehicles.totalCost(id);
  }
}
