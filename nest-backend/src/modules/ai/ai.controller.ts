import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { QueueService } from '../../queue/queue.service';
import { AiChatDto } from './dto/ai-chat.dto';
import { AiService } from './ai.service';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(
    private readonly ai: AiService,
    private readonly queue: QueueService,
  ) {}

  @Get('insights')
  insights(@Req() req: { user: { userId: string } }) {
    return this.ai.insights(req.user.userId);
  }

  /**
   * Queue a background regeneration of persisted insights (BullMQ when Redis is up).
   * Falls back to synchronous analyze when Redis is disabled.
   */
  @Post('insights/analyze')
  async analyzeInsights(@Req() req: { user: { userId: string } }) {
    const userId = req.user.userId;
    const queued = await this.queue.enqueueAiInsightsJob(userId);
    if (queued) {
      return { queued: true, message: 'Insight analysis scheduled' };
    }
    const result = await this.ai.analyzeUserFinancialData(userId);
    return { queued: false, stored: result.stored, message: 'Analyzed inline (Redis queue unavailable)' };
  }

  /** Financial Q&A using the user’s ledger snapshot + optional prior turns. */
  @Post('chat')
  chat(@Req() req: { user: { userId: string } }, @Body() dto: AiChatDto) {
    return this.ai.chat(req.user.userId, dto);
  }
}
