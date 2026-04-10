import { Module } from '@nestjs/common';
import { InvestmentsController } from './investments.controller';
import { InvestmentsService } from './investments.service';
import { LiabilitiesController } from './liabilities.controller';
import { LiabilitiesService } from './liabilities.service';

@Module({
  controllers: [InvestmentsController, LiabilitiesController],
  providers: [InvestmentsService, LiabilitiesService],
})
export class WealthModule {}
