import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { QueueModule } from '../../queue/queue.module';
import { AiController } from './ai.controller';
import { AiInsightsProcessor } from './ai-insights.processor';
import { AiService } from './ai.service';

@Module({
  imports: [QueueModule, NotificationsModule],
  controllers: [AiController],
  providers: [AiService, AiInsightsProcessor],
  exports: [AiService],
})
export class AiModule {}
