import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminDashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async overview() {
    const now = new Date();
    const sevenAgo = new Date(now.getTime() - 7 * 86400000);
    const thirtyAgo = new Date(now.getTime() - 30 * 86400000);

    const [
      totalUsers,
      bannedUsers,
      expenseAgg,
      incomeAgg,
      expenseCount,
      incomeCount,
      usageSessions,
    ] = await Promise.all([
      this.prisma.user.count({ where: { deletedAt: null } }),
      this.prisma.user.count({
        where: { deletedAt: null, appUserStatus: 'banned' },
      }),
      this.prisma.expense.aggregate({
        _sum: { amount: true },
        where: { user: { deletedAt: null } },
      }),
      this.prisma.income.aggregate({
        _sum: { amount: true },
        where: { user: { deletedAt: null } },
      }),
      this.prisma.expense.count({ where: { user: { deletedAt: null } } }),
      this.prisma.income.count({ where: { user: { deletedAt: null } } }),
      this.prisma.appUsageEvent.groupBy({
        by: ['sessionId'],
        where: {
          createdAt: { gte: sevenAgo },
          sessionId: { not: null },
        },
      }),
    ]);

    const activeExpenseUsers = await this.prisma.expense.groupBy({
      by: ['userId'],
      where: { date: { gte: sevenAgo } },
    });
    const activeIncomeUsers = await this.prisma.income.groupBy({
      by: ['userId'],
      where: { date: { gte: sevenAgo } },
    });
    const activeRefreshUsers = await this.prisma.refreshToken.groupBy({
      by: ['userId'],
      where: { lastUsedAt: { gte: sevenAgo } },
    });
    const activeIds = new Set<string>();
    for (const r of activeExpenseUsers) activeIds.add(r.userId);
    for (const r of activeIncomeUsers) activeIds.add(r.userId);
    for (const r of activeRefreshUsers) activeIds.add(r.userId);

    const userGrowth = await this.prisma.$queryRaw<
      { month: string; count: bigint }[]
    >`
      SELECT to_char(date_trunc('month', "createdAt"), 'YYYY-MM') AS month, COUNT(*)::bigint AS count
      FROM "User"
      WHERE "deletedAt" IS NULL
      GROUP BY 1
      ORDER BY 1 ASC
      LIMIT 18
    `;

    const [expByDay, incByDay] = await Promise.all([
      this.prisma.$queryRaw<{ day: string; c: bigint }[]>`
        SELECT (date_trunc('day', "date") AT TIME ZONE 'UTC')::date::text AS day, COUNT(*)::bigint AS c
        FROM "Expense" WHERE "date" >= ${thirtyAgo}
        GROUP BY 1 ORDER BY 1 ASC`,
      this.prisma.$queryRaw<{ day: string; c: bigint }[]>`
        SELECT (date_trunc('day', "date") AT TIME ZONE 'UTC')::date::text AS day, COUNT(*)::bigint AS c
        FROM "Income" WHERE "date" >= ${thirtyAgo}
        GROUP BY 1 ORDER BY 1 ASC`,
    ]);
    const em = new Map(expByDay.map((r) => [r.day, Number(r.c)]));
    const im = new Map(incByDay.map((r) => [r.day, Number(r.c)]));
    const dailyTx: { day: string; expenses: number; incomes: number }[] = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now);
      d.setUTCDate(d.getUTCDate() - i);
      const key = d.toISOString().slice(0, 10);
      dailyTx.push({
        day: key,
        expenses: em.get(key) ?? 0,
        incomes: im.get(key) ?? 0,
      });
    }

    const expenseTotal = Number(expenseAgg._sum.amount ?? 0);
    const incomeTotal = Number(incomeAgg._sum.amount ?? 0);

    return {
      cards: {
        totalUsers,
        activeUsersLast7Days: activeIds.size,
        bannedUsers,
        totalTransactions: expenseCount + incomeCount,
        totalExpense: expenseTotal,
        totalIncome: incomeTotal,
        appUsageSessionCount7d: usageSessions.length,
      },
      charts: {
        userGrowth: userGrowth.map((r) => ({
          month: r.month,
          count: Number(r.count),
        })),
        dailyTransactions: dailyTx.map((r) => ({
          day: r.day,
          expenses: Number(r.expenses),
          incomes: Number(r.incomes),
        })),
        incomeVsExpense: [
          { name: 'Income', value: incomeTotal },
          { name: 'Expense', value: expenseTotal },
        ],
      },
    };
  }

  async analyticsDetail() {
    const since = new Date(Date.now() - 30 * 86400000);
    const [usageDays, expDays, incDays] = await Promise.all([
      this.prisma.$queryRaw<{ day: string; userId: string }[]>`
        SELECT (date_trunc('day', "createdAt") AT TIME ZONE 'UTC')::date::text AS day, "userId"
        FROM "AppUsageEvent" WHERE "createdAt" >= ${since}`,
      this.prisma.$queryRaw<{ day: string; userId: string }[]>`
        SELECT (date_trunc('day', "date") AT TIME ZONE 'UTC')::date::text AS day, "userId"
        FROM "Expense" WHERE "date" >= ${since}`,
      this.prisma.$queryRaw<{ day: string; userId: string }[]>`
        SELECT (date_trunc('day', "date") AT TIME ZONE 'UTC')::date::text AS day, "userId"
        FROM "Income" WHERE "date" >= ${since}`,
    ]);
    const dauMap = new Map<string, Set<string>>();
    const add = (day: string, uid: string) => {
      if (!dauMap.has(day)) dauMap.set(day, new Set());
      dauMap.get(day)!.add(uid);
    };
    for (const r of usageDays) add(r.day, r.userId);
    for (const r of expDays) add(r.day, r.userId);
    for (const r of incDays) add(r.day, r.userId);
    const dau = [...dauMap.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([day, set]) => ({ day, users: set.size }));

    const screenUsage = await this.prisma.appUsageEvent.groupBy({
      by: ['screen'],
      _count: { id: true },
      _sum: { durationMs: true },
      where: { createdAt: { gte: since } },
      orderBy: { _count: { id: 'desc' } },
      take: 20,
    });

    const loginFreq = await this.prisma.refreshToken.groupBy({
      by: ['userId'],
      _count: { id: true },
      where: { lastUsedAt: { not: null } },
      orderBy: { _count: { id: 'desc' } },
      take: 25,
    });

    return {
      dailyActiveUsers: dau,
      screenUsage: screenUsage.map((r) => ({
        screen: r.screen,
        events: r._count.id,
        durationMs: r._sum.durationMs ?? 0,
      })),
      loginFrequencyTop: loginFreq.map((r) => ({
        userId: r.userId,
        sessions: r._count.id,
      })),
    };
  }
}
