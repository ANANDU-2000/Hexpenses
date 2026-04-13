import { Injectable } from '@nestjs/common';
import { CategoryType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminBudgetsService {
  constructor(private readonly prisma: PrismaService) {}

  /** List budgets with spent vs limit for current calendar month (UTC). */
  async listWithOverspend(userId?: string) {
    const now = new Date();
    const yearMonth = now.getUTCFullYear() * 100 + (now.getUTCMonth() + 1);

    const budgets = await this.prisma.budget.findMany({
      where: {
        yearMonth,
        ...(userId ? { userId } : {}),
      },
      include: {
        category: true,
        user: { select: { id: true, name: true, email: true } },
      },
      orderBy: { user: { email: 'asc' } },
      take: 500,
    });

    const out = [];
    for (const b of budgets) {
      if (b.category.type !== CategoryType.expense) continue;
      const { start, end } = monthRangeUtc(yearMonth);
      const agg = await this.prisma.expense.aggregate({
        where: {
          userId: b.userId,
          categoryId: b.categoryId,
          date: { gte: start, lt: end },
        },
        _sum: { amount: true },
      });
      const spent = Number(agg._sum.amount ?? 0);
      const limit = Number(b.amountLimit);
      const exceeded = spent > limit;
      out.push({
        id: b.id,
        userId: b.userId,
        user: b.user,
        category: { id: b.category.id, name: b.category.name },
        limit,
        spent,
        exceeded,
        percent: limit > 0 ? Math.min(999, (spent / limit) * 100) : 0,
        yearMonth: b.yearMonth,
      });
    }
    return { rows: out, overspending: out.filter((r) => r.exceeded) };
  }
}

function monthRangeUtc(yearMonth: number): { start: Date; end: Date } {
  const y = Math.floor(yearMonth / 100);
  const m = yearMonth % 100;
  const start = new Date(Date.UTC(y, m - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(y, m, 1, 0, 0, 0, 0));
  return { start, end };
}
