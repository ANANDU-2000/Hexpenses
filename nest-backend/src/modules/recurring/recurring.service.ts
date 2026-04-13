import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import {
  ExpenseSource,
  Frequency,
  NotificationCategory,
  RecurringMode,
  RecurringStatus,
} from '@prisma/client';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { QueueService } from '../../queue/queue.service';
import { AccountsService } from '../accounts/accounts.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRecurringDto } from './dto/create-recurring.dto';

@Injectable()
export class RecurringService implements OnModuleInit {
  private readonly logger = new Logger(RecurringService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly queue: QueueService,
    private readonly accounts: AccountsService,
    private readonly notifications: NotificationsService,
  ) {}

  onModuleInit() {
    this.queue.createRecurringWorker(async (job) => {
      await this.processRecurring(job.data.recurringId);
    });
    if (!this.queue.redisAvailable) {
      this.logger.warn('Recurring worker not started (no Redis); due items are processed inline from the cron job');
    }
  }

  list(userId: string) {
    return this.prisma.recurringExpense.findMany({
      where: { userId },
      include: { category: true, account: true },
      orderBy: { nextDate: 'asc' },
    });
  }

  create(userId: string, dto: CreateRecurringDto) {
    return this.prisma.recurringExpense.create({
      data: {
        userId,
        amount: dto.amount,
        frequency: dto.frequency,
        mode: dto.mode ?? RecurringMode.auto_create,
        nextDate: new Date(dto.nextDate),
        categoryId: dto.categoryId,
        accountId: dto.accountId,
        title: dto.title,
        note: dto.note,
      },
      include: { category: true, account: true },
    });
  }

  async setActive(userId: string, id: string, active: boolean) {
    const row = await this.prisma.recurringExpense.findFirst({
      where: { id, userId },
    });
    if (!row) throw new NotFoundException('Recurring expense not found');
    return this.prisma.recurringExpense.update({
      where: { id },
      data: { active },
      include: { category: true, account: true },
    });
  }

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async scheduleDueRecurring() {
    if (this.prisma.databaseDisabled) return;
    const due = await this.prisma.recurringExpense.findMany({
      where: { active: true, nextDate: { lte: new Date() } },
    });
    for (const item of due) {
      if (!this.queue.recurringQueue) {
        await this.processRecurring(item.id);
        continue;
      }
      await this.queue.recurringQueue.add(
        'apply-recurring',
        { recurringId: item.id },
        { jobId: `recurring-${item.id}-${item.nextDate.toISOString().slice(0, 10)}` },
      );
    }
  }

  async processRecurring(recurringId: string) {
    const item = await this.prisma.recurringExpense.findUnique({ where: { id: recurringId } });
    if (!item || !item.active) return;

    if (item.mode === RecurringMode.reminder_only) {
      const dueDay = item.nextDate.toISOString().slice(0, 10);
      const dedupeKey = `recurring-reminder-${item.id}-${dueDay}`;
      await this.notifications.create(item.userId, `Recurring due: ${item.title}`, NotificationCategory.recurring, {
        body: `${item.amount.toFixed(2)} ${item.currency} · ${item.frequency}`,
        dedupeKey,
      });
      await this.prisma.recurringExpense.update({
        where: { id: recurringId },
        data: {
          status: RecurringStatus.pending,
          nextDate: this.nextDate(item.nextDate, item.frequency),
        },
      });
      return;
    }

    const occurrenceDate = item.nextDate;
    await this.prisma.$transaction(async (tx) => {
      const expense = await tx.expense.create({
        data: {
          userId: item.userId,
          categoryId: item.categoryId,
          amount: item.amount,
          date: item.nextDate,
          note: item.note ?? item.title,
          currency: item.currency,
          source: ExpenseSource.recurring_generated,
          recurringExpenseId: item.id,
          accountId: item.accountId ?? undefined,
        },
        include: { category: true },
      });
      if (item.accountId) {
        await this.accounts.applyExpenseCreatedTx(tx, item.userId, {
          accountId: expense.accountId,
          amount: expense.amount,
          category: expense.category,
        });
      }
      await tx.recurringExpense.update({
        where: { id: recurringId },
        data: {
          status: 'paid',
          nextDate: this.nextDate(item.nextDate, item.frequency),
        },
      });
    });

    const postedDedupe = `recurring-posted-${item.id}-${occurrenceDate.toISOString().slice(0, 10)}`;
    void this.notifications
      .create(item.userId, `Expense logged: ${item.title}`, NotificationCategory.recurring, {
        body: `${item.amount.toFixed(2)} ${item.currency}`,
        dedupeKey: postedDedupe,
      })
      .catch((e) => this.logger.warn(`recurring push notify: ${(e as Error).message}`));
  }

  private nextDate(date: Date, frequency: Frequency) {
    const next = new Date(date);
    if (frequency === Frequency.daily) next.setDate(next.getDate() + 1);
    if (frequency === Frequency.weekly) next.setDate(next.getDate() + 7);
    if (frequency === Frequency.monthly) next.setMonth(next.getMonth() + 1);
    if (frequency === Frequency.quarterly) next.setMonth(next.getMonth() + 3);
    if (frequency === Frequency.yearly) next.setFullYear(next.getFullYear() + 1);
    return next;
  }
}
