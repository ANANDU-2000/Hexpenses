import { Module, forwardRef } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { BudgetsModule } from '../budgets/budgets.module';
import { WorkspacesModule } from '../workspaces/workspaces.module';
import { ExpensesController } from './expenses.controller';
import { ExpensesRepository } from './expenses.repository';
import { ExpensesService } from './expenses.service';
import { LedgerController } from './ledger.controller';

@Module({
  imports: [AccountsModule, WorkspacesModule, forwardRef(() => BudgetsModule)],
  controllers: [ExpensesController, LedgerController],
  providers: [ExpensesRepository, ExpensesService],
  exports: [ExpensesService],
})
export class ExpensesModule {}
