import { Controller, Get, Query, Req, Res, UseGuards } from '@nestjs/common';
import { Response } from 'express';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';
import { RequestWithWorkspace } from '../workspaces/workspace.types';
import { ReportsService } from './reports.service';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get('monthly-summary')
  monthlySummary(@Req() req: { user: { userId: string } }) {
    return this.reports.monthlySummary(req.user.userId);
  }

  /** Calendar month income totals and by-source breakdown; optional `year` / `month` (1–12), defaults to now. */
  @Get('monthly-income')
  monthlyIncome(
    @Req() req: { user: { userId: string } },
    @Query('year') year?: string,
    @Query('month') month?: string,
  ) {
    return this.reports.monthlyIncomeReport(req.user.userId, year, month);
  }

  @Get('category-breakdown')
  categoryBreakdown(@Req() req: { user: { userId: string } }) {
    return this.reports.categoryBreakdown(req.user.userId);
  }

  /** GST (India) / VAT (UAE) summary for taxable expenses in the current workspace and month. */
  @Get('tax-summary')
  @UseGuards(WorkspaceContextGuard)
  taxSummary(
    @Req() req: RequestWithWorkspace,
    @Query('year') year?: string,
    @Query('month') month?: string,
    @Query('details') details?: string,
  ) {
    const d = details === '1' || details === 'true';
    return this.reports.taxSummary(req.workspaceContext, year, month, d);
  }

  /** Overview: this month cash flow, net worth (accounts + investments − liabilities), multi-month trend for charts. */
  @Get('dashboard')
  dashboard(
    @Req() req: { user: { userId: string } },
    @Query('trendMonths') trendMonths?: string,
  ) {
    const n = trendMonths ? Number(trendMonths) : 6;
    return this.reports.dashboard(req.user.userId, Number.isFinite(n) ? n : 6);
  }

  @Get()
  async legacyReport(@Req() req: { user: { userId: string } }) {
    const [summary, byCategory] = await Promise.all([
      this.reports.monthlySummary(req.user.userId),
      this.reports.categoryBreakdown(req.user.userId),
    ]);
    return {
      totals: {
        expenses: summary.totalExpenses,
        income: summary.totalIncome,
        net_cash_flow: summary.netCashFlow,
      },
      expenses_by_category: byCategory,
    };
  }

  @Get('export')
  exportCsv(
    @Res() res: Response,
    @Query('format') format = 'csv',
  ) {
    if (format === 'pdf') {
      res.header('Content-Type', 'application/pdf');
      res.send(Buffer.from('MoneyFlow PDF export placeholder'));
      return;
    }
    res.header('Content-Type', 'text/csv');
    res.header('Content-Disposition', 'attachment; filename="moneyflow_export.csv"');
    res.send('Date,Type,Amount\n2026-01-01,expense,0');
  }
}
