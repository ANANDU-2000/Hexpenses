import { Controller, Get, Header, Query, UseGuards } from '@nestjs/common';
import { AppUserStatus } from '@prisma/client';
import { SkipResponseEnvelope } from '../../common/decorators/skip-response-envelope.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminJwtAuthGuard } from './admin-jwt.guard';

@Controller('admin/export')
@UseGuards(AdminJwtAuthGuard)
export class AdminExportController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('users.csv')
  @SkipResponseEnvelope()
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="users.csv"')
  async usersCsv(@Query('status') status?: AppUserStatus) {
    const rows = await this.prisma.user.findMany({
      where: { deletedAt: null, ...(status ? { appUserStatus: status } : {}) },
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
    });
    const header = 'id,name,email,phone,status,currency,createdAt\n';
    const body = rows
      .map((r) =>
        [
          r.id,
          csv(r.name),
          csv(r.email ?? ''),
          csv(r.phone ?? ''),
          r.appUserStatus,
          r.currency,
          r.createdAt.toISOString(),
        ].join(','),
      )
      .join('\n');
    return header + body;
  }

  @Get('transactions.csv')
  @SkipResponseEnvelope()
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="transactions.csv"')
  async transactionsCsv(
    @Query('userId') userId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const fromD = from ? new Date(from) : undefined;
    const toD = to ? new Date(to) : undefined;
    const dateQ =
      fromD || toD
        ? { date: { ...(fromD ? { gte: fromD } : {}), ...(toD ? { lte: toD } : {}) } }
        : {};
    const [expenses, incomes] = await Promise.all([
      this.prisma.expense.findMany({
        where: { ...(userId ? { userId } : {}), ...dateQ },
        include: { category: true, user: { select: { email: true } } },
        orderBy: { date: 'desc' },
        take: 5000,
      }),
      this.prisma.income.findMany({
        where: { ...(userId ? { userId } : {}), ...dateQ },
        include: { user: { select: { email: true } } },
        orderBy: { date: 'desc' },
        take: 5000,
      }),
    ]);
    const header = 'kind,id,userId,userEmail,amount,date,category,note\n';
    const lines: string[] = [];
    for (const e of expenses) {
      lines.push(
        [
          'expense',
          e.id,
          e.userId,
          csv(e.user.email ?? ''),
          e.amount.toString(),
          e.date.toISOString(),
          csv(e.category.name),
          csv(e.note ?? ''),
        ].join(','),
      );
    }
    for (const i of incomes) {
      lines.push(
        [
          'income',
          i.id,
          i.userId,
          csv(i.user.email ?? ''),
          i.amount.toString(),
          i.date.toISOString(),
          i.source,
          csv(i.note ?? ''),
        ].join(','),
      );
    }
    return header + lines.join('\n');
  }
}

function csv(s: string) {
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}
