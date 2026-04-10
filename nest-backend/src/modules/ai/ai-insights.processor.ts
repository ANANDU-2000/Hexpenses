import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { QueueService } from '../../queue/queue.service';
import { AiService } from './ai.service';

@Injectable()
export class AiInsightsProcessor implements OnModuleInit {
  private readonly logger = new Logger(AiInsightsProcessor.name);

  constructor(
    private readonly queue: QueueService,
    private readonly ai: AiService,
  ) {}

  onModuleInit() {
    this.queue.createAiInsightsWorker(async (job) => {
      try {
        await this.ai.analyzeUserFinancialData(job.data.userId);
      } catch (e) {
        this.logger.warn(`AI insights job failed: ${(e as Error).message}`);
      }
    });
  }
}
