import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateLiabilityDto } from './dto/create-liability.dto';
import { UpdateLiabilityDto } from './dto/update-liability.dto';
import { LiabilitiesService } from './liabilities.service';

@Controller('liabilities')
@UseGuards(JwtAuthGuard)
export class LiabilitiesController {
  constructor(private readonly liabilities: LiabilitiesService) {}

  @Get()
  list(@Req() req: { user: { userId: string } }) {
    return this.liabilities.list(req.user.userId);
  }

  @Post()
  create(@Req() req: { user: { userId: string } }, @Body() dto: CreateLiabilityDto) {
    return this.liabilities.create(req.user.userId, dto);
  }

  @Patch(':id')
  update(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
    @Body() dto: UpdateLiabilityDto,
  ) {
    return this.liabilities.update(req.user.userId, id, dto);
  }

  @Delete(':id')
  remove(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.liabilities.remove(req.user.userId, id);
  }
}
