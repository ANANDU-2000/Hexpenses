import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { WorkspacesModule } from '../workspaces/workspaces.module';
import { IncomesController } from './incomes.controller';
import { IncomesRepository } from './incomes.repository';
import { IncomesService } from './incomes.service';

@Module({
  imports: [AccountsModule, WorkspacesModule],
  controllers: [IncomesController],
  providers: [IncomesService, IncomesRepository],
  exports: [IncomesService],
})
export class IncomesModule {}
