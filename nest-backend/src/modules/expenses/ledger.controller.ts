import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';
import { RequestWithWorkspace } from '../workspaces/workspace.types';
import { ListExpenseDto } from './dto/list-expense.dto';
import { ExpensesService } from './expenses.service';

@Controller('ledger')
@UseGuards(JwtAuthGuard, WorkspaceContextGuard)
export class LedgerController {
  constructor(private readonly expenses: ExpensesService) {}

  @Get()
  list(@Req() req: RequestWithWorkspace, @Query() query: ListExpenseDto) {
    return this.expenses.findAll(req.workspaceContext, query);
  }

  @Get('summary')
  async summary(@Req() req: RequestWithWorkspace) {
    const rows = await this.expenses.findAll(req.workspaceContext, {});
    const total = rows.reduce((sum: number, row: { amount: unknown }) => sum + Number(row.amount), 0);
    return { total_income: '0.00', total_expenses: total.toFixed(2), balance: `-${total.toFixed(2)}` };
  }
}
