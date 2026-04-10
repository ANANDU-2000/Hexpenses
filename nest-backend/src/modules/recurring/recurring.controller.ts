import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateRecurringDto } from './dto/create-recurring.dto';
import { RecurringService } from './recurring.service';

@Controller('recurring')
@UseGuards(JwtAuthGuard)
export class RecurringController {
  constructor(private readonly recurring: RecurringService) {}

  @Get()
  list(@Req() req: { user: { userId: string } }) {
    return this.recurring.list(req.user.userId);
  }

  @Post()
  create(@Req() req: { user: { userId: string } }, @Body() dto: CreateRecurringDto) {
    return this.recurring.create(req.user.userId, dto);
  }
}
