import { Injectable } from "@nestjs/common";
import { AccountType, CategoryType, PaymentMode, Prisma } from "@prisma/client";
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

  /** Local midnight YYYY-MM-DD */
  private parseYmdLocal(ymd: string): Date | null {
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(ymd.trim());
    if (!m) return null;
    const y = Number(m[1]);
    const mo = Number(m[2]);
    const d = Number(m[3]);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    const dt = new Date(y, mo - 1, d, 0, 0, 0, 0);
    if (
      dt.getFullYear() !== y ||
      dt.getMonth() !== mo - 1 ||
      dt.getDate() !== d
    ) {
      return null;
    }
    return dt;
  }

  private dayAfterStartOf(d: Date): Date {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1, 0, 0, 0, 0);
  }

  /**
   * Calendar month (year/month) OR inclusive YYYY-MM-DD range (from/to).
   * Expenses use `date >= start` and `date < endExclusive`.
   */
  private resolveExpenseMvpWindow(
    yearStr: string | undefined,
    monthStr: string | undefined,
    fromStr: string | undefined,
    toStr: string | undefined,
    now = new Date(),
  ): { start: Date; endExclusive: Date; label: string } {
    if (fromStr?.trim() && toStr?.trim()) {
      const s = this.parseYmdLocal(fromStr.trim());
      const t = this.parseYmdLocal(toStr.trim());
      if (s && t && s <= t) {
        return {
          start: s,
          endExclusive: this.dayAfterStartOf(t),
          label: `${fromStr.trim()} → ${toStr.trim()}`,
        };
      }
    }
    const fb = this.parseYearMonth(yearStr, monthStr, now);
    return { start: fb.start, endExclusive: fb.end, label: fb.label };
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
    assertWorkspacePermission(ctx.role, "expense:read");
    const [thisMonth, trend, netWorthBreakdown, allTimeExpenses] =
      await Promise.all([
        this.monthlySummary(ctx),
        this.savingsTrend(ctx, trendMonths),
        this.netWorth(ctx),
        this.prisma.expense.aggregate({
          where: {
            userId: ctx.ownerUserId,
            workspaceId: ctx.workspaceId,
            category: { type: CategoryType.expense },
          },
          _sum: { amount: true },
        }),
      ]);
    return {
      thisMonth,
      netWorth: netWorthBreakdown,
      savingsTrend: trend,
      totalSpentAllTime: Number(allTimeExpenses._sum.amount ?? 0).toFixed(2),
      recurringMonthlyTotal: "0",
      recurringNote: "Recurring total — fuller module after MVP.",
      upcomingPayments: { count: 0, note: "Upcoming — after MVP." },
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
      select: {
        categoryId: true,
        amount: true,
        category: {
          select: { name: true, systemKey: true, sortOrder: true },
        },
      },
    });
    const totals = new Map<
      string,
      { total: number; name: string; systemKey: string | null; sortOrder: number }
    >();
    for (const row of rows) {
      const prev = totals.get(row.categoryId);
      const add = Number(row.amount);
      if (prev) {
        prev.total += add;
      } else {
        totals.set(row.categoryId, {
          total: add,
          name: row.category.name,
          systemKey: row.category.systemKey,
          sortOrder: row.category.sortOrder,
        });
      }
    }
    return [...totals.entries()]
      .map(([categoryId, v]) => ({
        categoryId,
        name: v.name,
        systemKey: v.systemKey,
        sortOrder: v.sortOrder,
        total: v.total.toFixed(2),
      }))
      .sort((a, b) => {
        const o = a.sortOrder - b.sortOrder;
        if (o !== 0) return o;
        return a.name.localeCompare(b.name);
      });
  }

  /**
   * Chart-ready MVP payload: lifetime spend, month-scoped category pie data,
   * expense-only monthly bars, placeholders for recurring / vehicle / upcoming.
   */
  async expenseMvp(
    ctx: WorkspaceContext,
    yearStr?: string,
    monthStr?: string,
    trendMonths = 12,
    fromStr?: string,
    toStr?: string,
  ) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const { start, endExclusive, label } = this.resolveExpenseMvpWindow(
      yearStr,
      monthStr,
      fromStr,
      toStr,
    );
    const months = Math.min(24, Math.max(1, Math.floor(trendMonths)));

    const baseWhere = {
      userId: ctx.ownerUserId,
      workspaceId: ctx.workspaceId,
      category: { type: CategoryType.expense },
    } as const;

    const [allTimeAgg, monthRows, trendRows, vehicleCount] = await Promise.all([
      this.prisma.expense.aggregate({
        where: baseWhere,
        _sum: { amount: true },
      }),
      this.prisma.expense.findMany({
        where: { ...baseWhere, date: { gte: start, lt: endExclusive } },
        select: {
          amount: true,
          categoryId: true,
          category: {
            select: { name: true, systemKey: true, sortOrder: true },
          },
        },
      }),
      this.prisma.expense.findMany({
        where: baseWhere,
        select: { amount: true, date: true },
      }),
      this.prisma.vehicle.count({ where: { userId: ctx.ownerUserId } }),
    ]);

    const totalSpentAllTime = Number(allTimeAgg._sum.amount ?? 0);

    const byCatMonth = new Map<
      string,
      { total: number; name: string; systemKey: string | null; sortOrder: number }
    >();
    for (const row of monthRows) {
      const prev = byCatMonth.get(row.categoryId);
      const add = Number(row.amount);
      if (prev) {
        prev.total += add;
      } else {
        byCatMonth.set(row.categoryId, {
          total: add,
          name: row.category.name,
          systemKey: row.category.systemKey,
          sortOrder: row.category.sortOrder,
        });
      }
    }

    const categoryBreakdownMonth = [...byCatMonth.entries()]
      .map(([categoryId, v]) => ({
        categoryId,
        name: v.name,
        systemKey: v.systemKey,
        total: v.total.toFixed(2),
      }))
      .sort((a, b) => {
        const av = byCatMonth.get(a.categoryId)!;
        const bv = byCatMonth.get(b.categoryId)!;
        const o = av.sortOrder - bv.sortOrder;
        if (o !== 0) return o;
        return a.name.localeCompare(b.name);
      });

    const pieLabels = categoryBreakdownMonth.map((r) => r.name);
    const pieValues = categoryBreakdownMonth.map((r) => Number(r.total));
    const pieCategoryIds = categoryBreakdownMonth.map((r) => r.categoryId);

    const expenseByMonth = new Map<string, number>();
    for (const row of trendRows) {
      const k = this.monthKey(row.date);
      expenseByMonth.set(k, (expenseByMonth.get(k) ?? 0) + Number(row.amount));
    }

    const now = new Date();
    const monthlyExpenseTrend: {
      month: string;
      label: string;
      total: string;
      totalNum: number;
    }[] = [];
    for (let i = months - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
      const short = d.toLocaleString("en-US", { month: "short" });
      const v = expenseByMonth.get(key) ?? 0;
      monthlyExpenseTrend.push({
        month: key,
        label: short,
        total: v.toFixed(2),
        totalNum: v,
      });
    }

    const barLabels = monthlyExpenseTrend.map((m) => m.label);
    const barValues = monthlyExpenseTrend.map((m) => m.totalNum);

    const vehicleExpenseAgg = await this.prisma.vehicleExpense.aggregate({
      where: { vehicle: { userId: ctx.ownerUserId } },
      _sum: { amount: true },
    });
    const vehicleCostsTotal = Number(vehicleExpenseAgg._sum.amount ?? 0);

    return {
      period: label,
      totalSpentAllTime: totalSpentAllTime.toFixed(2),
      thisMonthExpenses: monthRows
        .reduce((s, r) => s + Number(r.amount), 0)
        .toFixed(2),
      categoryBreakdownMonth,
      chart: {
        pie: {
          labels: pieLabels,
          values: pieValues,
          categoryIds: pieCategoryIds,
        },
        monthlyExpenses: {
          labels: barLabels,
          values: barValues,
          months: monthlyExpenseTrend.map((m) => m.month),
        },
      },
      recurringMonthlyTotal: "0",
      recurringNote: "Coming soon — connect recurring module for a total.",
      vehicle: {
        hasVehicles: vehicleCount > 0,
        vehicleExpenseTotalAllTime: vehicleCostsTotal.toFixed(2),
        emptyHint:
          vehicleCount === 0
            ? "Add a vehicle under Profile to track fuel & service here."
            : null,
      },
      upcomingPayments: {
        count: 0,
        note: "Upcoming bills — fuller module after MVP.",
      },
    };
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

  /**
   * Multi-level analytics: composable filters + pie for next drill level + monthly bars + stacked category×month.
   */
  async analyticsDrilldown(
    ctx: WorkspaceContext,
    params: {
      yearStr?: string;
      monthStr?: string;
      fromStr?: string;
      toStr?: string;
      categoryId?: string;
      subCategoryId?: string;
      expenseTypeId?: string;
      spendEntityId?: string;
      paymentMode?: string;
    },
  ) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const { start, endExclusive, label } = this.resolveExpenseMvpWindow(
      params.yearStr,
      params.monthStr,
      params.fromStr,
      params.toStr,
    );

    let pm: PaymentMode | undefined;
    if (
      params.paymentMode &&
      (Object.values(PaymentMode) as string[]).includes(params.paymentMode)
    ) {
      pm = params.paymentMode as PaymentMode;
    }

    const baseWhere: Prisma.ExpenseWhereInput = {
      userId: ctx.ownerUserId,
      workspaceId: ctx.workspaceId,
      category: { type: CategoryType.expense },
      date: { gte: start, lt: endExclusive },
    };
    if (params.categoryId) baseWhere.categoryId = params.categoryId;
    if (params.subCategoryId) baseWhere.subCategoryId = params.subCategoryId;
    if (params.expenseTypeId) baseWhere.expenseTypeId = params.expenseTypeId;
    if (params.spendEntityId) baseWhere.spendEntityId = params.spendEntityId;
    if (pm) baseWhere.paymentMode = pm;

    const rows = await this.prisma.expense.findMany({
      where: baseWhere,
      select: {
        amount: true,
        date: true,
        categoryId: true,
        subCategoryId: true,
        expenseTypeId: true,
        spendEntityId: true,
        category: { select: { id: true, name: true, sortOrder: true } },
        subCategory: { select: { id: true, name: true, sortOrder: true } },
        expenseType: { select: { id: true, name: true } },
        spendEntity: { select: { id: true, name: true, kind: true } },
      },
    });

    const total = rows.reduce((s, r) => s + Number(r.amount), 0);
    const count = rows.length;

    type PieRow = {
      labels: string[];
      values: number[];
      ids: string[];
      level: string;
    };

    let pie: PieRow = { labels: [], values: [], ids: [], level: "none" };

    if (!params.categoryId) {
      const m = new Map<
        string,
        { name: string; total: number; sortOrder: number }
      >();
      for (const r of rows) {
        const id = r.categoryId;
        const add = Number(r.amount);
        const prev = m.get(id);
        if (prev) prev.total += add;
        else
          m.set(id, {
            name: r.category.name,
            total: add,
            sortOrder: r.category.sortOrder,
          });
      }
      const entries = [...m.entries()].sort((a, b) => {
        const o = a[1].sortOrder - b[1].sortOrder;
        if (o !== 0) return o;
        return a[1].name.localeCompare(b[1].name);
      });
      pie = {
        labels: entries.map(([, v]) => v.name),
        values: entries.map(([, v]) => v.total),
        ids: entries.map(([k]) => k),
        level: "category",
      };
    } else if (!params.subCategoryId) {
      const m = new Map<string, { name: string; total: number; sort: number }>();
      for (const r of rows) {
        if (!r.subCategoryId || !r.subCategory) continue;
        const id = r.subCategoryId;
        const add = Number(r.amount);
        const prev = m.get(id);
        if (prev) prev.total += add;
        else
          m.set(id, {
            name: r.subCategory.name,
            total: add,
            sort: r.subCategory.sortOrder,
          });
      }
      const unassigned = rows
        .filter((r) => !r.subCategoryId)
        .reduce((s, r) => s + Number(r.amount), 0);
      if (unassigned > 0) {
        m.set("__unassigned__", {
          name: "Unassigned",
          total: unassigned,
          sort: 9999,
        });
      }
      const entries = [...m.entries()].sort((a, b) => {
        const o = a[1].sort - b[1].sort;
        if (o !== 0) return o;
        return a[1].name.localeCompare(b[1].name);
      });
      pie = {
        labels: entries.map(([, v]) => v.name),
        values: entries.map(([, v]) => v.total),
        ids: entries.map(([k]) => k),
        level: "subcategory",
      };
    } else if (!params.expenseTypeId) {
      const m = new Map<string, { name: string; total: number }>();
      for (const r of rows) {
        const id = r.expenseTypeId ?? "__none__";
        const name = r.expenseType?.name ?? "Unspecified type";
        const add = Number(r.amount);
        const prev = m.get(id);
        if (prev) prev.total += add;
        else m.set(id, { name, total: add });
      }
      const entries = [...m.entries()].sort((a, b) =>
        a[1].name.localeCompare(b[1].name),
      );
      pie = {
        labels: entries.map(([, v]) => v.name),
        values: entries.map(([, v]) => v.total),
        ids: entries.map(([k]) => k),
        level: "expenseType",
      };
    } else if (!params.spendEntityId) {
      const m = new Map<string, { name: string; total: number }>();
      for (const r of rows) {
        const id = r.spendEntityId ?? "__none__";
        const name = r.spendEntity?.name ?? "Unspecified entity";
        const add = Number(r.amount);
        const prev = m.get(id);
        if (prev) prev.total += add;
        else m.set(id, { name, total: add });
      }
      const entries = [...m.entries()].sort((a, b) =>
        a[1].name.localeCompare(b[1].name),
      );
      pie = {
        labels: entries.map(([, v]) => v.name),
        values: entries.map(([, v]) => v.total),
        ids: entries.map(([k]) => k),
        level: "entity",
      };
    } else {
      pie = {
        labels: ["Selected slice"],
        values: [total],
        ids: [params.spendEntityId],
        level: "leaf",
      };
    }

    const monthBuckets: { key: string; label: string }[] = [];
    for (
      let d = new Date(start.getFullYear(), start.getMonth(), 1);
      d < endExclusive;
      d = new Date(d.getFullYear(), d.getMonth() + 1, 1)
    ) {
      const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
      const labelShort = d.toLocaleString("en-US", { month: "short" });
      monthBuckets.push({ key, label: labelShort });
    }
    if (monthBuckets.length === 0) {
      const key = `${start.getFullYear()}-${start.getMonth() + 1}`;
      monthBuckets.push({
        key,
        label: start.toLocaleString("en-US", { month: "short" }),
      });
    }

    const monthlyValues = monthBuckets.map(({ key }) => {
      const [ys, ms] = key.split("-").map(Number);
      const msStart = new Date(ys, ms - 1, 1);
      const msEnd = new Date(ys, ms, 1);
      let s = 0;
      for (const r of rows) {
        const t = r.date.getTime();
        if (t >= msStart.getTime() && t < msEnd.getTime()) s += Number(r.amount);
      }
      return s;
    });

    const catKeys = new Map<string, { name: string; sort: number }>();
    for (const r of rows) {
      if (!catKeys.has(r.categoryId))
        catKeys.set(r.categoryId, {
          name: r.category.name,
          sort: r.category.sortOrder,
        });
    }
    const categoriesOrdered = [...catKeys.entries()].sort((a, b) => {
      const o = a[1].sort - b[1].sort;
      if (o !== 0) return o;
      return a[1].name.localeCompare(b[1].name);
    });

    const stacked = {
      months: monthBuckets.map((m) => m.key),
      monthLabels: monthBuckets.map((m) => m.label),
      series: categoriesOrdered.map(([cid, meta]) => {
        const values = monthBuckets.map(({ key }) => {
          const [ys, ms] = key.split("-").map(Number);
          const msStart = new Date(ys, ms - 1, 1);
          const msEnd = new Date(ys, ms, 1);
          let s = 0;
          for (const r of rows) {
            if (r.categoryId !== cid) continue;
            const t = r.date.getTime();
            if (t >= msStart.getTime() && t < msEnd.getTime())
              s += Number(r.amount);
          }
          return s;
        });
        return { categoryId: cid, name: meta.name, values };
      }),
    };

    const lineTrend = {
      labels: monthBuckets.map((m) => m.label),
      values: monthlyValues,
    };

    return {
      period: label,
      total: total.toFixed(2),
      count,
      average: count > 0 ? (total / count).toFixed(2) : "0",
      pie,
      chart: {
        monthlyBar: {
          labels: monthBuckets.map((m) => m.label),
          values: monthlyValues,
        },
        lineTrend,
        stackedCategoryMonth: stacked,
      },
      filters: {
        categoryId: params.categoryId ?? null,
        subCategoryId: params.subCategoryId ?? null,
        expenseTypeId: params.expenseTypeId ?? null,
        spendEntityId: params.spendEntityId ?? null,
        paymentMode: pm ?? null,
      },
    };
  }

  /** Lightweight anomaly / trend hints for dashboard (rule-based). */
  async insightsSnapshot(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const now = new Date();
    const curStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const curEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const prevStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevEnd = curStart;

    const [curRows, prevRows] = await Promise.all([
      this.prisma.expense.findMany({
        where: {
          userId: ctx.ownerUserId,
          workspaceId: ctx.workspaceId,
          category: { type: CategoryType.expense },
          date: { gte: curStart, lt: curEnd },
        },
        select: { amount: true, categoryId: true, category: { select: { name: true } } },
      }),
      this.prisma.expense.findMany({
        where: {
          userId: ctx.ownerUserId,
          workspaceId: ctx.workspaceId,
          category: { type: CategoryType.expense },
          date: { gte: prevStart, lt: prevEnd },
        },
        select: { amount: true },
      }),
    ]);

    const curTotal = curRows.reduce((s, r) => s + Number(r.amount), 0);
    const prevTotal = prevRows.reduce((s, r) => s + Number(r.amount), 0);
    const delta = curTotal - prevTotal;
    const pct =
      prevTotal > 0 ? ((delta / prevTotal) * 100).toFixed(1) : null;

    const byCat = new Map<string, { name: string; total: number }>();
    for (const r of curRows) {
      const id = r.categoryId;
      const add = Number(r.amount);
      const prev = byCat.get(id);
      if (prev) prev.total += add;
      else byCat.set(id, { name: r.category.name, total: add });
    }
    let top: { categoryId: string; name: string; total: string } | null =
      null;
    for (const [categoryId, v] of byCat) {
      if (!top || v.total > parseFloat(top.total)) {
        top = { categoryId, name: v.name, total: v.total.toFixed(2) };
      }
    }

    const alerts: { severity: "info" | "warn"; message: string }[] = [];
    if (pct != null && Number(pct) > 15) {
      alerts.push({
        severity: "warn",
        message: `Spending is ${pct}% higher than last month.`,
      });
    }
    if (pct != null && Number(pct) < -10) {
      alerts.push({
        severity: "info",
        message: `Spending is ${Math.abs(Number(pct))}% lower than last month.`,
      });
    }

    return {
      thisMonthTotal: curTotal.toFixed(2),
      lastMonthTotal: prevTotal.toFixed(2),
      monthOverMonthPct: pct,
      topCategoryThisMonth: top,
      alerts,
    };
  }
}
