import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateInvestmentDto } from './dto/create-investment.dto';
import { UpdateInvestmentDto } from './dto/update-investment.dto';
import { InvestmentsService } from './investments.service';

@Controller('investments')
@UseGuards(JwtAuthGuard)
export class InvestmentsController {
  constructor(private readonly investments: InvestmentsService) {}

  @Get()
  list(@Req() req: { user: { userId: string } }) {
    return this.investments.list(req.user.userId);
  }

  @Post()
  create(@Req() req: { user: { userId: string } }, @Body() dto: CreateInvestmentDto) {
    return this.investments.create(req.user.userId, dto);
  }

  @Patch(':id')
  update(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
    @Body() dto: UpdateInvestmentDto,
  ) {
    return this.investments.update(req.user.userId, id, dto);
  }

  @Delete(':id')
  remove(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.investments.remove(req.user.userId, id);
  }
}
