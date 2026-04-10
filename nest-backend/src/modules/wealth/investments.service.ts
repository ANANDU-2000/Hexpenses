import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateInvestmentDto } from './dto/create-investment.dto';
import { UpdateInvestmentDto } from './dto/update-investment.dto';

function num(d: Prisma.Decimal | null | undefined): number {
  return Number(d ?? 0);
}

function serializeHolding(row: {
  id: string;
  name: string;
  kind: string;
  investedAmount: Prisma.Decimal;
  currentValue: Prisma.Decimal;
  note: string | null;
  createdAt: Date;
  updatedAt: Date;
}) {
  const invested = num(row.investedAmount);
  const current = num(row.currentValue);
  const profitLoss = current - invested;
  const profitLossPercent = invested > 0 ? (profitLoss / invested) * 100 : current > 0 ? 100 : 0;
  return {
    id: row.id,
    name: row.name,
    kind: row.kind,
    investedAmount: invested,
    currentValue: current,
    profitLoss,
    profitLossPercent: Math.round(profitLossPercent * 100) / 100,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

@Injectable()
export class InvestmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    const rows = await this.prisma.investment.findMany({
      where: { userId },
      orderBy: [{ kind: 'asc' }, { name: 'asc' }],
    });
    const holdings = rows.map(serializeHolding);
    let totalInvested = 0;
    let totalCurrent = 0;
    for (const h of holdings) {
      totalInvested += h.investedAmount;
      totalCurrent += h.currentValue;
    }
    const profitLoss = totalCurrent - totalInvested;
    const profitLossPercent =
      totalInvested > 0 ? Math.round((profitLoss / totalInvested) * 10000) / 100 : totalCurrent > 0 ? 100 : 0;
    return {
      holdings,
      summary: {
        totalInvested,
        totalCurrentValue: totalCurrent,
        profitLoss,
        profitLossPercent,
        holdingCount: holdings.length,
      },
    };
  }

  create(userId: string, dto: CreateInvestmentDto) {
    return this.prisma.investment
      .create({
        data: {
          userId,
          name: dto.name.trim(),
          kind: dto.kind,
          investedAmount: dto.investedAmount,
          currentValue: dto.currentValue,
          note: dto.note?.trim() || null,
        },
      })
      .then(serializeHolding);
  }

  async update(userId: string, id: string, dto: UpdateInvestmentDto) {
    const row = await this.prisma.investment.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Investment not found');
    return this.prisma.investment
      .update({
        where: { id },
        data: {
          ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
          ...(dto.kind !== undefined ? { kind: dto.kind } : {}),
          ...(dto.investedAmount !== undefined ? { investedAmount: dto.investedAmount } : {}),
          ...(dto.currentValue !== undefined ? { currentValue: dto.currentValue } : {}),
          ...(dto.note !== undefined ? { note: dto.note === null ? null : dto.note.trim() || null } : {}),
        },
      })
      .then(serializeHolding);
  }

  async remove(userId: string, id: string) {
    const row = await this.prisma.investment.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Investment not found');
    await this.prisma.investment.delete({ where: { id } });
    return { deleted: true };
  }
}
