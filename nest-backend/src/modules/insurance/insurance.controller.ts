import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { InsuranceService } from './insurance.service';

@Controller('insurance')
@UseGuards(JwtAuthGuard)
export class InsuranceController {
  constructor(private readonly insurance: InsuranceService) {}

  @Get('policies')
  list(@Req() req: { user: { userId: string } }) {
    return this.insurance.list(req.user.userId);
  }

  @Post('policies')
  create(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.insurance.create(req.user.userId, body);
  }
}
