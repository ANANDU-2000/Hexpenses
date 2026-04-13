import { Injectable, NotFoundException } from '@nestjs/common';
import { AppUserStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminActivityService } from './admin-activity.service';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activity: AdminActivityService,
  ) {}

  async list(q: {
    search?: string;
    status?: AppUserStatus;
    skip?: number;
    take?: number;
  }) {
    const where: Prisma.UserWhereInput = { deletedAt: null };
    if (q.status) where.appUserStatus = q.status;
    if (q.search?.trim()) {
      const s = q.search.trim();
      where.OR = [
        { email: { contains: s, mode: 'insensitive' } },
        { name: { contains: s, mode: 'insensitive' } },
      ];
    }
    const [rows, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip: q.skip ?? 0,
        take: Math.min(q.take ?? 50, 200),
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          appUserStatus: true,
          currency: true,
          createdAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { rows, total };
  }

  async detail(id: string) {
    const user = await this.prisma.user.findFirst({
      where: { id, deletedAt: null },
      include: {
        accounts: { select: { id: true, balance: true, type: true } },
        _count: {
          select: {
            expenses: true,
            incomes: true,
            notifications: true,
          },
        },
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const balanceSum = user.accounts.reduce(
      (acc, a) => acc + Number(a.balance),
      0,
    );
    const lastExpense = await this.prisma.expense.findFirst({
      where: { userId: id },
      orderBy: { date: 'desc' },
      select: { date: true },
    });
    const lastIncome = await this.prisma.income.findFirst({
      where: { userId: id },
      orderBy: { date: 'desc' },
      select: { date: true },
    });
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      appUserStatus: user.appUserStatus,
      joinedAt: user.createdAt,
      currency: user.currency,
      totalBalance: balanceSum,
      accounts: user.accounts,
      stats: {
        expenseCount: user._count.expenses,
        incomeCount: user._count.incomes,
        notificationCount: user._count.notifications,
        lastExpenseAt: lastExpense?.date ?? null,
        lastIncomeAt: lastIncome?.date ?? null,
      },
    };
  }

  async setStatus(adminId: string, userId: string, status: AppUserStatus) {
    const u = await this.prisma.user.updateMany({
      where: { id: userId, deletedAt: null },
      data: { appUserStatus: status },
    });
    if (u.count === 0) throw new NotFoundException('User not found');
    await this.activity.log(adminId, 'user.status', { userId, status });
    return { ok: true };
  }

  async remove(adminId: string, userId: string) {
    const u = await this.prisma.user.updateMany({
      where: { id: userId, deletedAt: null },
      data: { deletedAt: new Date() },
    });
    if (u.count === 0) throw new NotFoundException('User not found');
    await this.activity.log(adminId, 'user.soft_delete', { userId });
    return { ok: true };
  }
}
