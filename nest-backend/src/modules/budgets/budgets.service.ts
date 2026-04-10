import {
  BadRequestException,
  forwardRef,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditAction, CategoryType, NotificationCategory, Prisma } from '@prisma/client';
import { AuditEntity } from '../../audit/audit.types';
import { AuditService } from '../../audit/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { assertWorkspacePermission } from '../workspaces/workspace-permissions';
import { WorkspaceContext } from '../workspaces/workspace.types';
import { NotificationsService } from '../notifications/notifications.service';
import {
  formatMonthLabel,
  monthRangeUtc,
  parseMonthQuery,
  parseYearMonth,
  toYearMonth,
} from './budget-month.util';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';

export type BudgetStatusRow = {
  id: string;
  categoryId: string;
  categoryName: string;
  yearMonth: number;
  monthLabel: string;
  limit: string;
  spent: string;
  remaining: string;
  percentUsed: number;
  exceeded: boolean;
};

@Injectable()
export class BudgetsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => NotificationsService))
    private readonly notifications: NotificationsService,
    private readonly audit: AuditService,
  ) {}

  private async spentInMonth(
    userId: string,
    categoryId: string,
    yearMonth: number,
    workspaceId: string,
  ): Promise<Prisma.Decimal> {
    const { start, end } = monthRangeUtc(yearMonth);
    const agg = await this.prisma.expense.aggregate({
      where: {
        userId,
        workspaceId,
        categoryId,
        date: { gte: start, lt: end },
        category: { type: CategoryType.expense },
      },
      _sum: { amount: true },
    });
    return new Prisma.Decimal(agg._sum.amount ?? 0);
  }

  private async maybeAlertExceeded(
    userId: string,
    categoryId: string,
    categoryName: string,
    yearMonth: number,
    spent: Prisma.Decimal,
    limit: Prisma.Decimal,
  ) {
    if (!spent.greaterThan(limit)) return;
    const { year, month } = parseYearMonth(yearMonth);
    const dedupeKey = `budget-exceeded-${userId}-${year}-${month}-${categoryName.slice(0, 40)}`;
    await this.notifications.create(
      userId,
      'Budget exceeded',
      NotificationCategory.system,
      {
        body: `${categoryName}: spent ${spent.toFixed(2)} vs budget ${limit.toFixed(2)} (${formatMonthLabel(yearMonth)}).`,
        dedupeKey,
      },
    );
  }

  /** After an expense change, notify if that category’s monthly budget is now over the limit. */
  async notifyIfBudgetExceededForExpense(
    userId: string,
    workspaceId: string,
    categoryId: string,
    expenseDate: Date,
  ) {
    const yearMonth = toYearMonth(expenseDate.getUTCFullYear(), expenseDate.getUTCMonth() + 1);
    const budget = await this.prisma.budget.findUnique({
      where: {
        userId_categoryId_yearMonth: { userId, categoryId, yearMonth },
      },
      include: { category: true },
    });
    if (!budget || budget.category.type !== CategoryType.expense) return;
    const spent = await this.spentInMonth(userId, categoryId, yearMonth, workspaceId);
    const limit = budget.amountLimit;
    if (spent.greaterThan(limit)) {
      await this.maybeAlertExceeded(
        userId,
        categoryId,
        budget.category.name,
        yearMonth,
        spent,
        limit,
      );
    }
  }

  async listWithStatus(ctx: WorkspaceContext, month?: string): Promise<BudgetStatusRow[]> {
    assertWorkspacePermission(ctx.role, 'budget:read');
    const userId = ctx.ownerUserId;
    const yearMonth = parseMonthQuery(month);
    const rows = await this.prisma.budget.findMany({
      where: { userId, yearMonth },
      include: { category: true },
      orderBy: { category: { name: 'asc' } },
    });

    const out: BudgetStatusRow[] = [];
    for (const b of rows) {
      if (b.category.type !== CategoryType.expense) continue;
      const spent = await this.spentInMonth(userId, b.categoryId, yearMonth, ctx.workspaceId);
      const limit = b.amountLimit;
      const remaining = limit.minus(spent);
      const exceeded = spent.greaterThan(limit);
      const pct =
        limit.equals(0) || limit.lessThanOrEqualTo(0)
          ? 0
          : Number(spent.div(limit).mul(100).toFixed(1));

      if (exceeded) {
        await this.maybeAlertExceeded(userId, b.categoryId, b.category.name, yearMonth, spent, limit);
      }

      out.push({
        id: b.id,
        categoryId: b.categoryId,
        categoryName: b.category.name,
        yearMonth,
        monthLabel: formatMonthLabel(yearMonth),
        limit: limit.toFixed(2),
        spent: spent.toFixed(2),
        remaining: remaining.toFixed(2),
        percentUsed: Math.min(999, Math.max(0, pct)),
        exceeded,
      });
    }
    return out;
  }

  async create(ctx: WorkspaceContext, dto: CreateBudgetDto) {
    assertWorkspacePermission(ctx.role, 'budget:write');
    const userId = ctx.ownerUserId;
    const cat = await this.prisma.category.findFirst({
      where: { id: dto.categoryId, userId },
    });
    if (!cat) throw new BadRequestException('Invalid category');
    if (cat.type !== CategoryType.expense) {
      throw new BadRequestException('Budgets apply to expense categories only');
    }
    const yearMonth = parseMonthQuery(dto.month);
    try {
      const row = await this.prisma.budget.create({
        data: {
          userId,
          categoryId: dto.categoryId,
          amountLimit: dto.limit,
          yearMonth,
        },
        include: { category: true },
      });
      const spent = await this.spentInMonth(userId, row.categoryId, yearMonth, ctx.workspaceId);
      if (spent.greaterThan(row.amountLimit)) {
        await this.maybeAlertExceeded(
          userId,
          row.categoryId,
          row.category.name,
          yearMonth,
          spent,
          row.amountLimit,
        );
      }
      this.audit.logAction({
        userId: ctx.memberUserId,
        action: AuditAction.CREATE,
        entity: AuditEntity.Budget,
        entityId: row.id,
        metadata: {
          workspaceId: ctx.workspaceId,
          categoryId: row.categoryId,
          yearMonth: row.yearMonth,
          limit: row.amountLimit.toString(),
        },
      });
      return row;
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new BadRequestException('A budget already exists for this category and month');
      }
      throw e;
    }
  }

  async update(ctx: WorkspaceContext, id: string, dto: UpdateBudgetDto) {
    assertWorkspacePermission(ctx.role, 'budget:write');
    const userId = ctx.ownerUserId;
    const existing = await this.prisma.budget.findFirst({ where: { id, userId } });
    if (!existing) throw new NotFoundException('Budget not found');
    const data: Prisma.BudgetUpdateInput = {};
    if (dto.limit !== undefined) data.amountLimit = dto.limit;
    if (dto.yearMonth !== undefined) data.yearMonth = dto.yearMonth;
    try {
      const row = await this.prisma.budget.update({
        where: { id },
        data,
        include: { category: true },
      });
      const ym = row.yearMonth;
      const spent = await this.spentInMonth(userId, row.categoryId, ym, ctx.workspaceId);
      if (spent.greaterThan(row.amountLimit)) {
        await this.maybeAlertExceeded(
          userId,
          row.categoryId,
          row.category.name,
          ym,
          spent,
          row.amountLimit,
        );
      }
      this.audit.logAction({
        userId: ctx.memberUserId,
        action: AuditAction.UPDATE,
        entity: AuditEntity.Budget,
        entityId: row.id,
        metadata: {
          workspaceId: ctx.workspaceId,
          categoryId: row.categoryId,
          yearMonth: row.yearMonth,
          limit: row.amountLimit.toString(),
          patch: {
            ...(dto.limit !== undefined ? { limit: dto.limit } : {}),
            ...(dto.yearMonth !== undefined ? { yearMonth: dto.yearMonth } : {}),
          },
        },
      });
      return row;
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new BadRequestException('A budget already exists for this category and month');
      }
      throw e;
    }
  }

  async remove(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, 'budget:write');
    const userId = ctx.ownerUserId;
    const row = await this.prisma.budget.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Budget not found');
    await this.prisma.budget.delete({ where: { id } });
    this.audit.logAction({
      userId: ctx.memberUserId,
      action: AuditAction.DELETE,
      entity: AuditEntity.Budget,
      entityId: id,
      metadata: {
        workspaceId: ctx.workspaceId,
        categoryId: row.categoryId,
        yearMonth: row.yearMonth,
      },
    });
    return { deleted: true };
  }
}
