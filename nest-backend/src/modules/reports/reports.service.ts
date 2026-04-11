import { Injectable } from "@nestjs/common";
import { AccountType, CategoryType } from "@prisma/client";
import { PrismaService } from "../../prisma/prisma.service";
import { assertWorkspacePermission } from "../workspaces/workspace-permissions";
import { WorkspaceContext } from "../workspaces/workspace.types";

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  private monthRange(now = new Date()) {
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    return { start, end, label: `${now.getFullYear()}-${now.getMonth() + 1}` };
  }

  private parseYearMonth(
    yearStr?: string,
    monthStr?: string,
    now = new Date(),
  ) {
    const y = yearStr ? Number(yearStr) : now.getFullYear();
    const m = monthStr ? Number(monthStr) : now.getMonth() + 1;
    if (!Number.isFinite(y) || !Number.isFinite(m) || m < 1 || m > 12) {
      return this.monthRange(now);
    }
    const start = new Date(y, m - 1, 1);
    const end = new Date(y, m, 1);
    return { start, end, label: `${y}-${m}` };
  }

  async monthlyIncomeReport(
    ctx: WorkspaceContext,
    yearStr?: string,
    monthStr?: string,
  ) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const { start, end, label } = this.parseYearMonth(yearStr, monthStr);
    const rows = await this.prisma.income.findMany({
      where: {
        userId: ctx.ownerUserId,
        date: { gte: start, lt: end },
        account: { workspaceId: ctx.workspaceId },
      },
      include: { account: true },
      orderBy: { date: "desc" },
    });
    const totalIncome = rows.reduce((sum, row) => sum + Number(row.amount), 0);
    const bySource = new Map<string, number>();
    for (const row of rows) {
      bySource.set(
        row.source,
        (bySource.get(row.source) ?? 0) + Number(row.amount),
      );
    }
    return {
      month: label,
      totalIncome: totalIncome.toFixed(2),
      incomeBySource: [...bySource.entries()].map(([source, total]) => ({
        source,
        total: total.toFixed(2),
      })),
      entries: rows,
    };
  }

  async monthlySummary(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const { start, end, label } = this.monthRange();
    const [expenseRows, incomeRows] = await Promise.all([
      this.prisma.expense.findMany({
        where: {
          userId: ctx.ownerUserId,
          workspaceId: ctx.workspaceId,
          date: { gte: start, lt: end },
          category: { type: CategoryType.expense },
        },
      }),
      this.prisma.income.findMany({
        where: {
          userId: ctx.ownerUserId,
          date: { gte: start, lt: end },
          account: { workspaceId: ctx.workspaceId },
        },
      }),
    ]);
    const totalExpenses = expenseRows.reduce(
      (sum, row) => sum + Number(row.amount),
      0,
    );
    const totalIncome = incomeRows.reduce(
      (sum, row) => sum + Number(row.amount),
      0,
    );
    const incomeBySource = new Map<string, number>();
    for (const row of incomeRows) {
      incomeBySource.set(
        row.source,
        (incomeBySource.get(row.source) ?? 0) + Number(row.amount),
      );
    }
    const net = totalIncome - totalExpenses;
    const netFixed = net.toFixed(2);
    return {
      month: label,
      totalExpenses: totalExpenses.toFixed(2),
      totalIncome: totalIncome.toFixed(2),
      netCashFlow: netFixed,
      netSavings: netFixed,
      incomeBySource: [...incomeBySource.entries()].map(([source, total]) => ({
        source,
        total: total.toFixed(2),
      })),
    };
  }

  private monthKey(d: Date) {
    return `${d.getFullYear()}-${d.getMonth() + 1}`;
  }

  /** Last `trendMonths` calendar months including current (max 24). */
  async savingsTrend(ctx: WorkspaceContext, trendMonths = 6) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const months = Math.min(24, Math.max(1, Math.floor(trendMonths)));
    const now = new Date();
    const rangeStart = new Date(
      now.getFullYear(),
      now.getMonth() - (months - 1),
      1,
    );
    const rangeEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    const [allIncomes, allExpenses] = await Promise.all([
      this.prisma.income.findMany({
        where: {
          userId: ctx.ownerUserId,
          date: { gte: rangeStart, lt: rangeEnd },
          account: { workspaceId: ctx.workspaceId },
        },
        select: { amount: true, date: true },
      }),
      this.prisma.expense.findMany({
        where: {
          userId: ctx.ownerUserId,
          workspaceId: ctx.workspaceId,
          date: { gte: rangeStart, lt: rangeEnd },
          category: { type: CategoryType.expense },
        },
        select: { amount: true, date: true },
      }),
    ]);

    const incomeByMonth = new Map<string, number>();
    const expenseByMonth = new Map<string, number>();
    for (const row of allIncomes) {
      const k = this.monthKey(row.date);
      incomeByMonth.set(k, (incomeByMonth.get(k) ?? 0) + Number(row.amount));
    }
    for (const row of allExpenses) {
      const k = this.monthKey(row.date);
      expenseByMonth.set(k, (expenseByMonth.get(k) ?? 0) + Number(row.amount));
    }

    const series: {
      month: string;
      income: string;
      expenses: string;
      netSavings: string;
    }[] = [];
    for (let i = months - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const label = `${d.getFullYear()}-${d.getMonth() + 1}`;
      const income = incomeByMonth.get(label) ?? 0;
      const expenses = expenseByMonth.get(label) ?? 0;
      const net = income - expenses;
      series.push({
        month: label,
        income: income.toFixed(2),
        expenses: expenses.toFixed(2),
        netSavings: net.toFixed(2),
      });
    }
    return series;
  }

  async netWorth(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, "account:read");
    const [accounts, invAgg, liabAgg] = await Promise.all([
      this.prisma.account.findMany({
        where: { userId: ctx.ownerUserId, workspaceId: ctx.workspaceId },
        select: { type: true, balance: true, name: true },
      }),
      this.prisma.investment.aggregate({
        where: { userId: ctx.ownerUserId },
        _sum: { currentValue: true },
      }),
      this.prisma.liability.aggregate({
        where: { userId: ctx.ownerUserId },
        _sum: { balance: true },
      }),
    ]);

    let bankCash = 0;
    let creditDebt = 0;
    for (const a of accounts) {
      const b = Number(a.balance);
      if (a.type === AccountType.credit) creditDebt += b;
      else bankCash += b;
    }
    const investments = Number(invAgg._sum.currentValue ?? 0);
    const liabilities = Number(liabAgg._sum.balance ?? 0);
    const total = bankCash + investments - creditDebt - liabilities;

    return {
      netWorth: total.toFixed(2),
      bankAndCash: bankCash.toFixed(2),
      creditCardDebt: creditDebt.toFixed(2),
      investments: investments.toFixed(2),
      otherLiabilities: liabilities.toFixed(2),
    };
  }

  async dashboard(ctx: WorkspaceContext, trendMonths = 6) {
    const [thisMonth, trend, netWorthBreakdown] = await Promise.all([
      this.monthlySummary(ctx),
      this.savingsTrend(ctx, trendMonths),
      this.netWorth(ctx),
    ]);
    return {
      thisMonth,
      netWorth: netWorthBreakdown,
      savingsTrend: trend,
    };
  }

  async categoryBreakdown(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const rows = await this.prisma.expense.findMany({
      where: {
        userId: ctx.ownerUserId,
        workspaceId: ctx.workspaceId,
        category: { type: CategoryType.expense },
      },
      select: { categoryId: true, amount: true },
    });
    const totals = new Map<string, number>();
    for (const row of rows) {
      totals.set(
        row.categoryId,
        (totals.get(row.categoryId) ?? 0) + Number(row.amount),
      );
    }
    return [...totals.entries()].map(([categoryId, total]) => ({
      categoryId,
      total: total.toFixed(2),
    }));
  }

  private schemeLabel(scheme: string) {
    if (scheme === "gst_in") return "India GST";
    if (scheme === "vat_ae") return "UAE VAT";
    return scheme;
  }

  /** Taxable expenses in the workspace for a calendar month (GST / VAT manual tracking). */
  async taxSummary(
    ctx: WorkspaceContext,
    yearStr?: string,
    monthStr?: string,
    includeDetails = false,
  ) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const { start, end, label } = this.parseYearMonth(yearStr, monthStr);
    const rows = await this.prisma.expense.findMany({
      where: {
        userId: ctx.ownerUserId,
        workspaceId: ctx.workspaceId,
        taxable: true,
        date: { gte: start, lt: end },
        category: { type: CategoryType.expense },
      },
      include: { category: { select: { name: true } } },
      orderBy: { date: "desc" },
    });

    const byScheme = new Map<
      string,
      {
        scheme: string;
        label: string;
        count: number;
        totalExpense: number;
        totalTax: number;
      }
    >();
    let totalExpense = 0;
    let totalTax = 0;

    for (const r of rows) {
      const a = Number(r.amount);
      const t = Number(r.taxAmount ?? 0);
      totalExpense += a;
      totalTax += t;
      const key = r.taxScheme ?? "unknown";
      if (!byScheme.has(key)) {
        byScheme.set(key, {
          scheme: key,
          label: this.schemeLabel(key),
          count: 0,
          totalExpense: 0,
          totalTax: 0,
        });
      }
      const b = byScheme.get(key)!;
      b.count += 1;
      b.totalExpense += a;
      b.totalTax += t;
    }

    const base = {
      period: label,
      totals: {
        taxableExpenseCount: rows.length,
        totalTaxableExpenseAmount: totalExpense.toFixed(2),
        totalTaxAmount: totalTax.toFixed(2),
        totalNetExcludingTax: (totalExpense - totalTax).toFixed(2),
      },
      byScheme: [...byScheme.values()].map((x) => ({
        scheme: x.scheme,
        label: x.label,
        count: x.count,
        totalExpense: x.totalExpense.toFixed(2),
        totalTax: x.totalTax.toFixed(2),
        netExcludingTax: (x.totalExpense - x.totalTax).toFixed(2),
      })),
    };

    if (!includeDetails) return base;

    return {
      ...base,
      lines: rows.map((r) => ({
        id: r.id,
        date: r.date.toISOString(),
        amount: Number(r.amount),
        taxAmount: r.taxAmount != null ? Number(r.taxAmount) : 0,
        taxScheme: r.taxScheme,
        taxSchemeLabel: r.taxScheme ? this.schemeLabel(r.taxScheme) : null,
        categoryName: r.category?.name ?? null,
        note: r.note,
      })),
    };
  }
}
