import { Controller, Get, Query, Req, Res, UseGuards } from "@nestjs/common";
import { Response } from "express";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { WorkspaceContextGuard } from "../workspaces/workspace-context.guard";
import { RequestWithWorkspace } from "../workspaces/workspace.types";
import { ReportsService } from "./reports.service";

@Controller("reports")
@UseGuards(JwtAuthGuard, WorkspaceContextGuard)
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get("monthly-summary")
  monthlySummary(@Req() req: RequestWithWorkspace) {
    return this.reports.monthlySummary(req.workspaceContext);
  }

  /** Calendar month income totals and by-source breakdown; optional `year` / `month` (1–12), defaults to now. */
  @Get("monthly-income")
  monthlyIncome(
    @Req() req: RequestWithWorkspace,
    @Query("year") year?: string,
    @Query("month") month?: string,
  ) {
    return this.reports.monthlyIncomeReport(req.workspaceContext, year, month);
  }

  @Get("category-breakdown")
  categoryBreakdown(@Req() req: RequestWithWorkspace) {
    return this.reports.categoryBreakdown(req.workspaceContext);
  }

  /**
   * MVP: lifetime spend, selected month category totals (chart-ready pie + monthly expense bars),
   * recurring/upcoming placeholders, vehicle cost summary.
   */
  /** Composable drill-down analytics (pie + monthly + stacked + line). */
  @Get("analytics")
  analytics(
    @Req() req: RequestWithWorkspace,
    @Query("year") year?: string,
    @Query("month") month?: string,
    @Query("from") from?: string,
    @Query("to") to?: string,
    @Query("categoryId") categoryId?: string,
    @Query("subCategoryId") subCategoryId?: string,
    @Query("expenseTypeId") expenseTypeId?: string,
    @Query("spendEntityId") spendEntityId?: string,
    @Query("paymentMode") paymentMode?: string,
  ) {
    return this.reports.analyticsDrilldown(req.workspaceContext, {
      yearStr: year,
      monthStr: month,
      fromStr: from,
      toStr: to,
      categoryId,
      subCategoryId,
      expenseTypeId,
      spendEntityId,
      paymentMode,
    });
  }

  @Get("insights")
  insights(@Req() req: RequestWithWorkspace) {
    return this.reports.insightsSnapshot(req.workspaceContext);
  }

  @Get("expense-mvp")
  expenseMvp(
    @Req() req: RequestWithWorkspace,
    @Query("year") year?: string,
    @Query("month") month?: string,
    @Query("trendMonths") trendMonths?: string,
    /** Inclusive YYYY-MM-DD range; when both set, overrides calendar month. */
    @Query("from") from?: string,
    @Query("to") to?: string,
  ) {
    const n = trendMonths ? Number(trendMonths) : 12;
    return this.reports.expenseMvp(
      req.workspaceContext,
      year,
      month,
      Number.isFinite(n) ? n : 12,
      from,
      to,
    );
  }

  /** GST (India) / VAT (UAE) summary for taxable expenses in the current workspace and month. */
  @Get("tax-summary")
  taxSummary(
    @Req() req: RequestWithWorkspace,
    @Query("year") year?: string,
    @Query("month") month?: string,
    @Query("details") details?: string,
  ) {
    const d = details === "1" || details === "true";
    return this.reports.taxSummary(req.workspaceContext, year, month, d);
  }

  /** Overview: this month cash flow, net worth (accounts + investments − liabilities), multi-month trend for charts. */
  @Get("dashboard")
  dashboard(
    @Req() req: RequestWithWorkspace,
    @Query("trendMonths") trendMonths?: string,
  ) {
    const n = trendMonths ? Number(trendMonths) : 6;
    return this.reports.dashboard(
      req.workspaceContext,
      Number.isFinite(n) ? n : 6,
    );
  }

  @Get()
  async legacyReport(@Req() req: RequestWithWorkspace) {
    const [summary, byCategory] = await Promise.all([
      this.reports.monthlySummary(req.workspaceContext),
      this.reports.categoryBreakdown(req.workspaceContext),
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

  @Get("export")
  exportCsv(@Res() res: Response, @Query("format") format = "csv") {
    if (format === "pdf") {
      res.header("Content-Type", "application/pdf");
      res.send(Buffer.from("MoneyFlow PDF export placeholder"));
      return;
    }
    res.header("Content-Type", "text/csv");
    res.header(
      "Content-Disposition",
      'attachment; filename="moneyflow_export.csv"',
    );
    res.send("Date,Type,Amount\n2026-01-01,expense,0");
  }
}
