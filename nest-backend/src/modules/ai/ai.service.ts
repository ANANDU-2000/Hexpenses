import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import {
  AiInsightStatus,
  AiInsightType,
  CategoryType,
  NotificationCategory,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { formatMonthLabel, monthRangeUtc, toYearMonth } from '../budgets/budget-month.util';
import { NotificationsService } from '../notifications/notifications.service';
import { AiChatDto } from './dto/ai-chat.dto';

type StructuredInsights = {
  monthlyFinancialSummary: string;
  spendingWarnings: string[];
  savingSuggestions: string[];
  budgetRecommendations: string[];
};

type InsightDraft = {
  type: AiInsightType;
  summary: string;
  payload: Prisma.InputJsonValue;
};

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly notifications: NotificationsService,
  ) {}

  private async notifyInsightsReady(userId: string, stored: number) {
    if (stored <= 0) return;
    const day = new Date().toISOString().slice(0, 10);
    await this.notifications.create(userId, 'New AI insights ready', NotificationCategory.ai, {
      body: `${stored} personalized insight${stored === 1 ? '' : 's'} — open the app to review.`,
      dedupeKey: `ai-insights-ready-${userId}-${day}`,
    });
  }

  private monthRange(offsetMonths: number, anchor = new Date()) {
    const d = new Date(anchor.getFullYear(), anchor.getMonth() + offsetMonths, 1);
    const start = new Date(d.getFullYear(), d.getMonth(), 1);
    const end = new Date(d.getFullYear(), d.getMonth() + 1, 1);
    return { start, end };
  }

  private async totalsForMonth(userId: string, start: Date, end: Date) {
    const [inc, exp] = await Promise.all([
      this.prisma.income.aggregate({
        where: { userId, date: { gte: start, lt: end } },
        _sum: { amount: true },
      }),
      this.prisma.expense.aggregate({
        where: {
          userId,
          date: { gte: start, lt: end },
          category: { type: CategoryType.expense },
        },
        _sum: { amount: true },
      }),
    ]);
    return {
      income: Number(inc._sum.amount ?? 0),
      expenses: Number(exp._sum.amount ?? 0),
    };
  }

  private async categoryTotalsByMonth(userId: string, start: Date, end: Date) {
    const rows = await this.prisma.expense.groupBy({
      by: ['categoryId'],
      where: {
        userId,
        date: { gte: start, lt: end },
        category: { type: CategoryType.expense },
      },
      _sum: { amount: true },
    });
    if (!rows.length) return [] as { categoryId: string; name: string; total: number }[];
    const cats = await this.prisma.category.findMany({
      where: { userId, id: { in: rows.map((r) => r.categoryId) } },
      select: { id: true, name: true },
    });
    const nameById = new Map(cats.map((c) => [c.id, c.name]));
    return rows.map((r) => ({
      categoryId: r.categoryId,
      name: nameById.get(r.categoryId) ?? r.categoryId,
      total: Number(r._sum.amount ?? 0),
    }));
  }

  /** Replace auto-generated product insights (alerts / trends / suggestions) for a fresh run. */
  private async persistInsightDrafts(
    userId: string,
    drafts: InsightDraft[],
    periodStart: Date,
    periodEnd: Date,
  ): Promise<number> {
    const productTypes: AiInsightType[] = [
      AiInsightType.SPENDING_ALERT,
      AiInsightType.TREND,
      AiInsightType.SUGGESTION,
    ];

    await this.prisma.$transaction([
      this.prisma.aiInsight.deleteMany({
        where: { userId, type: { in: productTypes } },
      }),
      ...(drafts.length
        ? [
            this.prisma.aiInsight.createMany({
              data: drafts.map((d) => ({
                userId,
                type: d.type,
                status: AiInsightStatus.ready,
                summary: d.summary,
                payload: d.payload as Prisma.InputJsonValue,
                periodStart,
                periodEnd,
              })),
            }),
          ]
        : []),
    ]);

    return drafts.length;
  }

  /**
   * Rule-based financial insights from ledger + budgets; optional OpenAI polish for summary text.
   * Persists rows typed SPENDING_ALERT, TREND, SUGGESTION with status ready.
   */
  async analyzeUserFinancialData(userId: string): Promise<{ stored: number }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { currency: true },
    });
    const currency = user?.currency ?? 'INR';

    const now = new Date();
    const yearMonth = toYearMonth(now.getUTCFullYear(), now.getUTCMonth() + 1);
    const { start: monthStart, end: monthEnd } = monthRangeUtc(yearMonth);
    const { start: t0, end: t1 } = this.monthRange(0, now);
    const { start: l0, end: l1 } = this.monthRange(-1, now);

    const [expenseCount, incomeCount, thisMonth, lastMonth, catThis, catLast, budgets] =
      await Promise.all([
        this.prisma.expense.count({ where: { userId } }),
        this.prisma.income.count({ where: { userId } }),
        this.totalsForMonth(userId, t0, t1),
        this.totalsForMonth(userId, l0, l1),
        this.categoryTotalsByMonth(userId, t0, t1),
        this.categoryTotalsByMonth(userId, l0, l1),
        this.prisma.budget.findMany({
          where: { userId, yearMonth },
          include: { category: true },
        }),
      ]);

    const drafts: InsightDraft[] = [];

    if (expenseCount === 0 && incomeCount === 0) {
      drafts.push({
        type: AiInsightType.TREND,
        summary: `Add income and expense transactions to unlock personalized alerts and trends in ${currency}.`,
        payload: { facet: 'onboarding', yearMonth },
      });
      drafts.push({
        type: AiInsightType.SUGGESTION,
        summary:
          'Log at least a few weeks of transactions so overspending and category trends become visible.',
        payload: { facet: 'general', channel: 'savings' },
      });
      const n = await this.persistInsightDrafts(userId, drafts, monthStart, monthEnd);
      await this.notifyInsightsReady(userId, n);
      return { stored: n };
    }

    const netThis = thisMonth.income - thisMonth.expenses;
    const netLast = lastMonth.income - lastMonth.expenses;

    for (const b of budgets) {
      if (b.category.type !== CategoryType.expense) continue;
      const agg = await this.prisma.expense.aggregate({
        where: {
          userId,
          categoryId: b.categoryId,
          date: { gte: monthStart, lt: monthEnd },
          category: { type: CategoryType.expense },
        },
        _sum: { amount: true },
      });
      const spent = Number(agg._sum.amount ?? 0);
      const limit = Number(b.amountLimit);
      if (spent > limit) {
        const over = spent - limit;
        const label = formatMonthLabel(yearMonth);
        drafts.push({
          type: AiInsightType.SPENDING_ALERT,
          summary: `${b.category.name} is over budget for ${label}: spent ${spent.toFixed(2)} ${currency} vs limit ${limit.toFixed(2)} (${over.toFixed(2)} over).`,
          payload: {
            facet: 'budget_exceeded',
            categoryId: b.categoryId,
            categoryName: b.category.name,
            yearMonth,
            spent,
            limit,
            overage: over,
          },
        });
      }
    }

    if (lastMonth.expenses > 0 && thisMonth.expenses > lastMonth.expenses * 1.1) {
      const pct = Math.round(((thisMonth.expenses - lastMonth.expenses) / lastMonth.expenses) * 100);
      drafts.push({
        type: AiInsightType.SPENDING_ALERT,
        summary: `Total spending is up ${pct}% vs last month (${thisMonth.expenses.toFixed(2)} vs ${lastMonth.expenses.toFixed(2)} ${currency}).`,
        payload: {
          facet: 'total_spend_mom',
          thisMonth: thisMonth.expenses,
          lastMonth: lastMonth.expenses,
          pct,
        },
      });
    }

    const lastMap = new Map(catLast.map((c) => [c.categoryId, c.total]));
    const momTuples: { name: string; pct: number; categoryId: string; thisVal: number; prev: number }[] =
      [];
    for (const c of catThis) {
      const prev = lastMap.get(c.categoryId) ?? 0;
      if (prev > 0 && c.total > prev * 1.15) {
        const pct = Math.round(((c.total - prev) / prev) * 100);
        momTuples.push({ name: c.name, pct, categoryId: c.categoryId, thisVal: c.total, prev });
      }
    }
    for (const t of momTuples.slice(0, 5)) {
      drafts.push({
        type: AiInsightType.TREND,
        summary: `${t.name} spending rose about ${t.pct}% vs last month (${t.thisVal.toFixed(2)} vs ${t.prev.toFixed(2)} ${currency}).`,
        payload: {
          facet: 'category_mom',
          categoryId: t.categoryId,
          pct: t.pct,
          thisMonth: t.thisVal,
          lastMonth: t.prev,
        },
      });
    }

    const shareThis = catThis.reduce((s, c) => s + c.total, 0);
    if (shareThis > 0 && catThis.length) {
      const sorted = [...catThis].sort((a, b) => b.total - a.total);
      const top = sorted[0];
      const sharePct = Math.round((top.total / shareThis) * 100);
      drafts.push({
        type: AiInsightType.TREND,
        summary: `${top.name} is about ${sharePct}% of this month’s expenses — the largest share of your ${currency} outflows.`,
        payload: {
          facet: 'category_concentration',
          categoryId: top.categoryId,
          sharePct,
          amount: top.total,
        },
      });
    }

    drafts.push({
      type: AiInsightType.TREND,
      summary: `This month: income ${thisMonth.income.toFixed(2)}, expenses ${thisMonth.expenses.toFixed(2)}, net ${netThis.toFixed(2)} ${currency}. Last month net was ${netLast.toFixed(2)} ${currency}.`,
      payload: {
        facet: 'monthly_net_compare',
        incomeThis: thisMonth.income,
        expenseThis: thisMonth.expenses,
        netThis,
        netLast,
      },
    });

    if (netThis < 0) {
      drafts.push({
        type: AiInsightType.SUGGESTION,
        summary: `You spent ${Math.abs(netThis).toFixed(2)} ${currency} more than you earned this month — pause discretionary buys and move a bill or subscription to next cycle if possible.`,
        payload: { facet: 'negative_net', channel: 'savings', netThis },
      });
    } else if (thisMonth.income > 0) {
      const rate = netThis / thisMonth.income;
      if (rate < 0.1) {
        drafts.push({
          type: AiInsightType.SUGGESTION,
          summary: `Savings rate is under 10% of income — try automating a fixed transfer on payday (${currency}).`,
          payload: { facet: 'low_savings_rate', channel: 'savings', rate },
        });
      } else {
        drafts.push({
          type: AiInsightType.SUGGESTION,
          summary: `You retained about ${(rate * 100).toFixed(0)}% of income — consider directing half of that to an emergency fund or debt prepayment.`,
          payload: { facet: 'positive_flow', channel: 'savings', rate },
        });
      }
    }

    drafts.push({
      type: AiInsightType.SUGGESTION,
      summary:
        'Set next month’s top two category budgets to about 90% of what you spent this month to build a small buffer.',
      payload: { facet: 'budget_trim', channel: 'budget' },
    });
    drafts.push({
      type: AiInsightType.SUGGESTION,
      summary:
        'Try one no-discretionary-spend day weekly and route the difference to savings — small streaks compound.',
      payload: { facet: 'habit', channel: 'savings' },
    });

    let toStore = drafts;
    if (this.hasAiProvider()) {
      try {
        toStore = await this.openaiPolishDrafts(drafts, currency);
      } catch (e) {
        this.logger.warn(`OpenAI polish skipped: ${(e as Error).message}`);
      }
    }

    const stored = await this.persistInsightDrafts(userId, toStore, monthStart, monthEnd);
    await this.notifyInsightsReady(userId, stored);
    return { stored };
  }

  private async openaiPolishDrafts(drafts: InsightDraft[], currency: string): Promise<InsightDraft[]> {
    const lines = drafts.map((d, i) => `${i + 1}. [${d.type}] ${d.summary}`).join('\n');
    const system = [
      'You refine personal-finance insight lines for an app user.',
      `Currency: ${currency}.`,
      'Return ONLY valid JSON: {"lines":["..."]} — same number of strings, same order as input.',
      'Each line: one clear sentence, max 240 characters, friendly tone, no markdown.',
    ].join(' ');
    const raw = await this.openaiComplete(
      [
        { role: 'system', content: system },
        { role: 'user', content: lines },
      ],
      true,
    );
    if (!raw) return drafts;
    try {
      const o = JSON.parse(raw) as { lines?: unknown };
      const lines = Array.isArray(o.lines) ? o.lines : null;
      if (!lines || lines.length !== drafts.length) return drafts;
      return drafts.map((d, i) => ({
        ...d,
        summary: String(lines[i]).slice(0, 500),
      }));
    } catch {
      return drafts;
    }
  }

  private async composeInsightsFromStored(userId: string) {
    const rows = await this.prisma.aiInsight.findMany({
      where: {
        userId,
        type: {
          in: [
            AiInsightType.SPENDING_ALERT,
            AiInsightType.TREND,
            AiInsightType.SUGGESTION,
          ],
        },
        status: AiInsightStatus.ready,
      },
      orderBy: { createdAt: 'desc' },
      take: 48,
    });
    if (!rows.length) return null;

    const latestBatchTime = rows[0].createdAt.getTime();
    const batch = rows.filter((r) => latestBatchTime - r.createdAt.getTime() <= 120_000);
    if (!batch.length) return null;

    const spendingWarnings = batch
      .filter((r) => r.type === AiInsightType.SPENDING_ALERT)
      .map((r) => r.summary)
      .filter((s): s is string => !!s?.trim());

    const trendLines = batch
      .filter((r) => r.type === AiInsightType.TREND)
      .map((r) => r.summary)
      .filter((s): s is string => !!s?.trim());

    const suggestions = batch.filter((r) => r.type === AiInsightType.SUGGESTION);
    const savingSuggestions = suggestions
      .filter((r) => {
        const p = r.payload as { channel?: string } | null;
        return p?.channel !== 'budget';
      })
      .map((r) => r.summary)
      .filter((s): s is string => !!s?.trim());

    const budgetRecommendations = suggestions
      .filter((r) => {
        const p = r.payload as { channel?: string; facet?: string } | null;
        return p?.channel === 'budget' || p?.facet === 'budget_trim';
      })
      .map((r) => r.summary)
      .filter((s): s is string => !!s?.trim());

    const monthlyFinancialSummary =
      trendLines.find((t) => t.includes('This month:')) ??
      trendLines[0] ??
      spendingWarnings[0] ??
      'Your latest insights are ready.';

    const insights = [...spendingWarnings, ...trendLines, ...savingSuggestions, ...budgetRecommendations];

    return {
      source: 'stored' as const,
      monthlyFinancialSummary,
      spendingWarnings,
      savingSuggestions,
      budgetRecommendations:
        budgetRecommendations.length > 0
          ? budgetRecommendations
          : [
              'Align category budgets with last month’s actuals, then trim the top spender by ~10%.',
            ],
      insights,
    };
  }

  private async buildFinancialContext(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { currency: true },
    });
    const currency = user?.currency ?? 'INR';

    const { start: t0, end: t1 } = this.monthRange(0);
    const { start: l0, end: l1 } = this.monthRange(-1);

    const [thisMonth, lastMonth, catThis, catLast, recentRows, incomeBySource] = await Promise.all([
      this.totalsForMonth(userId, t0, t1),
      this.totalsForMonth(userId, l0, l1),
      this.categoryTotalsByMonth(userId, t0, t1),
      this.categoryTotalsByMonth(userId, l0, l1),
      this.prisma.expense.findMany({
        where: { userId, category: { type: CategoryType.expense } },
        include: { category: true },
        orderBy: { date: 'desc' },
        take: 25,
      }),
      this.prisma.income.groupBy({
        by: ['source'],
        where: { userId, date: { gte: t0, lt: t1 } },
        _sum: { amount: true },
      }),
    ]);

    const netThis = thisMonth.income - thisMonth.expenses;
    const netLast = lastMonth.income - lastMonth.expenses;

    const lastMap = new Map(catLast.map((c) => [c.categoryId, c.total]));
    const momLines: string[] = [];
    for (const c of catThis) {
      const prev = lastMap.get(c.categoryId) ?? 0;
      if (prev > 0 && c.total > prev * 1.15) {
        const pct = Math.round(((c.total - prev) / prev) * 100);
        momLines.push(
          `${c.name}: this month ${c.total.toFixed(2)} ${currency}, last month ${prev.toFixed(2)} ${currency} (+${pct}% vs last month)`,
        );
      }
    }

    const catLines = catThis
      .sort((a, b) => b.total - a.total)
      .slice(0, 12)
      .map((c) => `${c.name}: ${c.total.toFixed(2)}`)
      .join('\n');

    const incomeSrcLines = incomeBySource
      .map((r) => `${r.source}: ${Number(r._sum.amount ?? 0).toFixed(2)}`)
      .join('\n');

    const recent = recentRows
      .map((r) => `${r.date.toISOString().slice(0, 10)} ${r.category.name} ${r.amount}`)
      .join('\n');

    return [
      `Currency: ${currency}`,
      `THIS MONTH: income ${thisMonth.income.toFixed(2)}, expenses ${thisMonth.expenses.toFixed(2)}, net savings ${netThis.toFixed(2)}`,
      `LAST MONTH: income ${lastMonth.income.toFixed(2)}, expenses ${lastMonth.expenses.toFixed(2)}, net savings ${netLast.toFixed(2)}`,
      `Income by source (this month):\n${incomeSrcLines || '(none)'}`,
      `Expense totals by category (this month):\n${catLines || '(none)'}`,
      momLines.length ? `Category increases vs last month (15%+):\n${momLines.join('\n')}` : '',
      `Recent expense rows (date category amount):\n${recent || '(none)'}`,
    ]
      .filter(Boolean)
      .join('\n\n');
  }

  private flattenStructured(s: StructuredInsights): string[] {
    const out: string[] = [];
    if (s.monthlyFinancialSummary) out.push(s.monthlyFinancialSummary);
    for (const x of s.spendingWarnings) {
      out.push(`Warning: ${x}`);
    }
    for (const x of s.savingSuggestions) {
      out.push(`Save: ${x}`);
    }
    for (const x of s.budgetRecommendations) {
      out.push(`Budget: ${x}`);
    }
    return out.length ? out : ['No insights available yet.'];
  }

  private heuristicStructured(
    thisMonth: { income: number; expenses: number },
    lastMonth: { income: number; expenses: number },
    currency: string,
    momTuples: { name: string; pct: number }[],
  ): StructuredInsights {
    const net = thisMonth.income - thisMonth.expenses;
    const monthlyFinancialSummary = `This month you had income of ${thisMonth.income.toFixed(2)} ${currency} and expenses of ${thisMonth.expenses.toFixed(2)} ${currency}, leaving net savings of ${net.toFixed(2)} ${currency}. Last month, expenses were ${lastMonth.expenses.toFixed(2)} ${currency}.`;

    const spendingWarnings = momTuples.slice(0, 6).map((t) => {
      return `You spent ${t.pct}% more on ${t.name} than last month.`;
    });

    if (
      spendingWarnings.length === 0 &&
      lastMonth.expenses > 0 &&
      thisMonth.expenses > lastMonth.expenses * 1.1
    ) {
      spendingWarnings.push(
        'Total spending is higher than last month - review discretionary categories.',
      );
    }

    return {
      monthlyFinancialSummary,
      spendingWarnings,
      savingSuggestions: [
        'Automate a transfer to savings on the day you receive income.',
        'Pause or cancel subscriptions you have not used in the last 60 days.',
        'Try one no-discretionary-spend day per week and track the difference.',
      ],
      budgetRecommendations: [
        'Set next month budget for your top two categories at 90% of what you spent this month.',
        'Keep fixed essentials under about half of take-home pay when possible.',
        'Rebuild category limits after any change in income or large one-off expenses.',
      ],
    };
  }

  /** True if OpenAI and/or Gemini (Google) API key is configured. */
  private hasAiProvider(): boolean {
    return !!(this.getGeminiKey() || this.config.get<string>('OPENAI_API_KEY')?.trim());
  }

  /** Gemini: GEMINI_API_KEY, or Render-style `gemini_api`. */
  private getGeminiKey(): string | undefined {
    return (
      this.config.get<string>('GEMINI_API_KEY')?.trim() ||
      this.config.get<string>('gemini_api')?.trim() ||
      this.config.get<string>('GOOGLE_API_KEY')?.trim()
    );
  }

  private async openaiComplete(
    messages: { role: string; content: string }[],
    jsonMode: boolean,
  ): Promise<string | null> {
    const geminiKey = this.getGeminiKey();
    if (geminiKey) {
      return this.geminiComplete(messages, jsonMode, geminiKey);
    }
    const openaiKey = this.config.get<string>('OPENAI_API_KEY')?.trim();
    if (!openaiKey) return null;
    return this.openaiChatComplete(messages, jsonMode, openaiKey);
  }

  private async openaiChatComplete(
    messages: { role: string; content: string }[],
    jsonMode: boolean,
    apiKey: string,
  ): Promise<string | null> {
    const model = this.config.get<string>('OPENAI_MODEL', 'gpt-4o-mini');
    const body: Record<string, unknown> = {
      model,
      messages,
      max_tokens: jsonMode ? 900 : 700,
    };
    if (jsonMode) {
      body.response_format = { type: 'json_object' };
    }
    const { data } = await axios.post('https://api.openai.com/v1/chat/completions', body, {
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      timeout: 60000,
    });
    const content = data?.choices?.[0]?.message?.content;
    return typeof content === 'string' ? content : null;
  }

  /** Google Gemini (Generative Language API) — same message shape as OpenAI chat. */
  private async geminiComplete(
    messages: { role: string; content: string }[],
    jsonMode: boolean,
    apiKey: string,
  ): Promise<string | null> {
    const model = this.config.get<string>('GEMINI_MODEL', 'gemini-1.5-flash');
    const systemTexts = messages.filter((m) => m.role === 'system').map((m) => m.content);
    const systemInstruction =
      systemTexts.length > 0
        ? { parts: [{ text: systemTexts.join('\n\n') }] }
        : undefined;
    const contents: { role: string; parts: { text: string }[] }[] = [];
    for (const m of messages) {
      if (m.role === 'system') continue;
      const role = m.role === 'assistant' ? 'model' : 'user';
      contents.push({ role, parts: [{ text: m.content }] });
    }
    if (contents.length === 0) return null;

    const body: Record<string, unknown> = {
      contents,
      ...(systemInstruction ? { systemInstruction } : {}),
      generationConfig: {
        maxOutputTokens: jsonMode ? 2048 : 1024,
        ...(jsonMode ? { responseMimeType: 'application/json' } : {}),
      },
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    const { data } = await axios.post(url, body, {
      params: { key: apiKey },
      headers: { 'Content-Type': 'application/json' },
      timeout: 90000,
    });
    const parts = data?.candidates?.[0]?.content?.parts;
    if (!Array.isArray(parts)) return null;
    const text = parts.map((p: { text?: string }) => p?.text ?? '').join('');
    return text.length ? text : null;
  }

  private parseStructured(raw: string): StructuredInsights | null {
    try {
      const o = JSON.parse(raw) as Record<string, unknown>;
      const monthlyFinancialSummary = String(
        o.monthlyFinancialSummary ?? o.monthly_summary ?? '',
      ).trim();
      const asArr = (keys: string[]) => {
        for (const k of keys) {
          const v = o[k];
          if (Array.isArray(v)) return v.map((x) => String(x).trim()).filter(Boolean);
        }
        return [];
      };
      const spendingWarnings = asArr(['spendingWarnings', 'spending_warnings']);
      const savingSuggestions = asArr(['savingSuggestions', 'saving_suggestions']);
      const budgetRecommendations = asArr(['budgetRecommendations', 'budget_recommendations']);
      if (!monthlyFinancialSummary) return null;
      return {
        monthlyFinancialSummary,
        spendingWarnings,
        savingSuggestions,
        budgetRecommendations,
      };
    } catch {
      return null;
    }
  }

  /** On-demand / fallback path: does not persist product insight rows. */
  private async insightsLive(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { currency: true },
    });
    const currency = user?.currency ?? 'INR';

    const { start: t0, end: t1 } = this.monthRange(0);
    const { start: l0, end: l1 } = this.monthRange(-1);

    const [thisMonth, lastMonth, catThis, catLast, expenseCount, incomeCount] = await Promise.all([
      this.totalsForMonth(userId, t0, t1),
      this.totalsForMonth(userId, l0, l1),
      this.categoryTotalsByMonth(userId, t0, t1),
      this.categoryTotalsByMonth(userId, l0, l1),
      this.prisma.expense.count({ where: { userId } }),
      this.prisma.income.count({ where: { userId } }),
    ]);

    if (expenseCount === 0 && incomeCount === 0) {
      return {
        source: 'heuristic' as const,
        monthlyFinancialSummary:
          'Add income and expense transactions to unlock personalized summaries and warnings.',
        spendingWarnings: [] as string[],
        savingSuggestions: [
          'Log at least a few weeks of transactions so patterns (and overspending) become visible.',
        ],
        budgetRecommendations: [
          'Once you have a full month of data, set simple per-category caps.',
        ],
        insights: ['Add transactions to receive insights.'],
      };
    }

    const lastMap = new Map(catLast.map((c) => [c.categoryId, c.total]));
    const momTuples: { name: string; pct: number }[] = [];
    for (const c of catThis) {
      const prev = lastMap.get(c.categoryId) ?? 0;
      if (prev > 0 && c.total > prev * 1.15) {
        const pct = Math.round(((c.total - prev) / prev) * 100);
        momTuples.push({ name: c.name, pct });
      }
    }

    const context = await this.buildFinancialContext(userId);
    const apiKeyConfigured = this.hasAiProvider();

    let structured: StructuredInsights;
    let source: 'openai' | 'gemini' | 'heuristic';

    const systemJsonPrompt = [
      'You are a disciplined personal finance advisor. Output ONLY valid JSON with these exact keys:',
      '{"monthlyFinancialSummary":"string (2-4 sentences: this month vs last - income, spending, net savings)",',
      '"spendingWarnings":["string",...] (short lines like "You spent 32% more on Fuel" ONLY when the user data supports it; else fewer or empty),',
      '"savingSuggestions":["string",...] (3-5 actionable tips tied to their data),',
      '"budgetRecommendations":["string",...] (3-5 concrete budget rules or category caps)}',
      'Rules: Use ONLY facts from the user data. Respect the stated currency. No markdown. No extra keys.',
    ].join(' ');

    if (apiKeyConfigured) {
      try {
        const text = await this.openaiComplete(
          [
            { role: 'system', content: systemJsonPrompt },
            { role: 'user', content: `User financial data:\n\n${context}` },
          ],
          true,
        );

        const parsed = text ? this.parseStructured(text) : null;
        if (parsed) {
          structured = {
            monthlyFinancialSummary: parsed.monthlyFinancialSummary,
            spendingWarnings: parsed.spendingWarnings.slice(0, 8),
            savingSuggestions: parsed.savingSuggestions.slice(0, 8),
            budgetRecommendations: parsed.budgetRecommendations.slice(0, 8),
          };
          source = this.getGeminiKey() ? 'gemini' : 'openai';
        } else {
          structured = this.heuristicStructured(thisMonth, lastMonth, currency, momTuples);
          source = 'heuristic';
        }
      } catch (e) {
        this.logger.warn(`OpenAI insights failed: ${(e as Error).message}`);
        structured = this.heuristicStructured(thisMonth, lastMonth, currency, momTuples);
        source = 'heuristic';
      }
    } else {
      structured = this.heuristicStructured(thisMonth, lastMonth, currency, momTuples);
      source = 'heuristic';
    }

    return {
      source,
      monthlyFinancialSummary: structured.monthlyFinancialSummary,
      spendingWarnings: structured.spendingWarnings,
      savingSuggestions: structured.savingSuggestions,
      budgetRecommendations: structured.budgetRecommendations,
      insights: this.flattenStructured(structured),
    };
  }

  /**
   * Prefer persisted product insights (from analyzeUserFinancialData / queue); otherwise live OpenAI/heuristic.
   */
  async insights(userId: string) {
    const stored = await this.composeInsightsFromStored(userId);
    if (stored) return stored;
    return this.insightsLive(userId);
  }

  async chat(userId: string, dto: AiChatDto) {
    const trimmed = dto.message?.trim();
    if (!trimmed) throw new BadRequestException('message is required');

    const context = await this.buildFinancialContext(userId);
    if (!this.hasAiProvider()) {
      return {
        reply:
          'The AI assistant needs GEMINI_API_KEY (or gemini_api) or OPENAI_API_KEY on the server. Meanwhile: compare this month category totals to last month, cap your top category at 90% of last month spend, and automate one savings transfer per paycheck.',
        source: 'heuristic' as const,
      };
    }

    const system =
      'You are a helpful personal finance coach. Answer the user using their snapshot when relevant. Be concise (under 200 words). If data is missing for their question, say what they should track first. Do not invent account balances or transactions not in the snapshot.';

    const hist = (dto.history ?? []).slice(-12);
    const messages: { role: string; content: string }[] = [
      { role: 'system', content: `${system}\n\n--- User snapshot ---\n${context}` },
      ...hist.map((h) => ({ role: h.role, content: h.content })),
      { role: 'user', content: trimmed },
    ];

    try {
      const text = await this.openaiComplete(messages, false);
      if (!text?.trim()) throw new Error('Empty completion');
      const src: 'gemini' | 'openai' = this.getGeminiKey() ? 'gemini' : 'openai';
      return { reply: text.trim(), source: src };
    } catch (e) {
      this.logger.warn(`OpenAI chat failed: ${(e as Error).message}`);
      throw new ServiceUnavailableException(
        'AI assistant is temporarily unavailable. Try again in a moment.',
      );
    }
  }
}
