import { Module } from '@nestjs/common';
import { AiModule } from '../ai/ai.module';
import { WorkspacesModule } from '../workspaces/workspaces.module';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';
import { InsightsController } from './insights.controller';

@Module({
  imports: [AiModule, WorkspacesModule],
  controllers: [ReportsController, InsightsController],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsModule {}
