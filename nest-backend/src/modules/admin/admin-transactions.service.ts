import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminActivityService } from './admin-activity.service';
import { AdminPatchExpenseDto } from './dto/admin-patch-expense.dto';
import { AdminPatchIncomeDto } from './dto/admin-patch-income.dto';

@Injectable()
export class AdminTransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activity: AdminActivityService,
  ) {}

  async list(q: {
    userId?: string;
    from?: string;
    to?: string;
    categoryId?: string;
    skip?: number;
    take?: number;
  }) {
    const from = q.from ? new Date(q.from) : undefined;
    const to = q.to ? new Date(q.to) : undefined;
    const dateFilter =
      from || to
        ? {
            date: {
              ...(from ? { gte: from } : {}),
              ...(to ? { lte: to } : {}),
            },
          }
        : {};

    const [expenses, incomes] = await Promise.all([
      this.prisma.expense.findMany({
        where: {
          ...(q.userId ? { userId: q.userId } : {}),
          ...(q.categoryId ? { categoryId: q.categoryId } : {}),
          ...dateFilter,
        },
        include: {
          category: { select: { id: true, name: true, type: true } },
          user: { select: { id: true, name: true, email: true } },
        },
        orderBy: { date: 'desc' },
        skip: q.skip ?? 0,
        take: Math.min(q.take ?? 40, 100),
      }),
      this.prisma.income.findMany({
        where: {
          ...(q.userId ? { userId: q.userId } : {}),
          ...dateFilter,
        },
        include: {
          user: { select: { id: true, name: true, email: true } },
          account: { select: { id: true, name: true } },
        },
        orderBy: { date: 'desc' },
        skip: q.skip ?? 0,
        take: Math.min(q.take ?? 40, 100),
      }),
    ]);

    const merged = [
      ...expenses.map((e) => ({
        kind: 'expense' as const,
        id: e.id,
        userId: e.userId,
        amount: Number(e.amount),
        date: e.date,
        note: e.note,
        categoryId: e.categoryId,
        categoryName: e.category.name,
        user: e.user,
        createdAt: e.createdAt,
      })),
      ...incomes.map((i) => ({
        kind: 'income' as const,
        id: i.id,
        userId: i.userId,
        amount: Number(i.amount),
        date: i.date,
        note: i.note,
        categoryId: null as string | null,
        categoryName: i.source,
        user: i.user,
        createdAt: i.createdAt,
      })),
    ].sort((a, b) => b.date.getTime() - a.date.getTime());

    return { rows: merged.slice(0, Math.min(q.take ?? 80, 150)) };
  }

  async patchExpense(adminId: string, id: string, dto: AdminPatchExpenseDto) {
    const exists = await this.prisma.expense.findFirst({ where: { id } });
    if (!exists) throw new NotFoundException('Expense not found');
    await this.prisma.expense.update({
      where: { id },
      data: {
        ...(dto.amount != null ? { amount: dto.amount } : {}),
        ...(dto.date ? { date: new Date(dto.date) } : {}),
        ...(dto.note !== undefined ? { note: dto.note } : {}),
        ...(dto.categoryId ? { categoryId: dto.categoryId } : {}),
      },
    });
    await this.activity.log(adminId, 'expense.update', { id });
    return { ok: true };
  }

  async deleteExpense(adminId: string, id: string) {
    const exists = await this.prisma.expense.findFirst({ where: { id } });
    if (!exists) throw new NotFoundException('Expense not found');
    await this.prisma.expense.delete({ where: { id } });
    await this.activity.log(adminId, 'expense.delete', { id });
    return { ok: true };
  }

  async patchIncome(adminId: string, id: string, dto: AdminPatchIncomeDto) {
    const exists = await this.prisma.income.findFirst({ where: { id } });
    if (!exists) throw new NotFoundException('Income not found');
    await this.prisma.income.update({
      where: { id },
      data: {
        ...(dto.amount != null ? { amount: dto.amount } : {}),
        ...(dto.date ? { date: new Date(dto.date) } : {}),
        ...(dto.note !== undefined ? { note: dto.note } : {}),
      },
    });
    await this.activity.log(adminId, 'income.update', { id });
    return { ok: true };
  }

  async deleteIncome(adminId: string, id: string) {
    const exists = await this.prisma.income.findFirst({ where: { id } });
    if (!exists) throw new NotFoundException('Income not found');
    await this.prisma.income.delete({ where: { id } });
    await this.activity.log(adminId, 'income.delete', { id });
    return { ok: true };
  }
}
