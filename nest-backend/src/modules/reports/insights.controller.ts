import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AiService } from '../ai/ai.service';

@Controller('insights')
@UseGuards(JwtAuthGuard)
export class InsightsController {
  constructor(private readonly ai: AiService) {}

  @Get()
  async list(@Req() req: { user: { userId: string } }) {
    return this.ai.insights(req.user.userId);
  }
}
