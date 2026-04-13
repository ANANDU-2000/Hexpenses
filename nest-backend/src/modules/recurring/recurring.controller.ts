import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateRecurringDto } from './dto/create-recurring.dto';
import { UpdateRecurringActiveDto } from './dto/update-recurring-active.dto';
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

  @Patch(':id/active')
  setActive(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
    @Body() dto: UpdateRecurringActiveDto,
  ) {
    return this.recurring.setActive(req.user.userId, id, dto.active);
  }
}
