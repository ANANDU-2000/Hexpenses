import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { serializeIncome } from '../../common/serialize-ledger';
import { PrismaService } from '../../prisma/prisma.service';
import { assertWorkspacePermission } from '../workspaces/workspace-permissions';
import { WorkspaceContext } from '../workspaces/workspace.types';
import { AccountsService } from '../accounts/accounts.service';
import { CreateIncomeDto } from './dto/create-income.dto';
import { ListIncomeDto } from './dto/list-income.dto';
import { UpdateIncomeDto } from './dto/update-income.dto';
import { IncomesRepository } from './incomes.repository';

@Injectable()
export class IncomesService {
  constructor(
    private readonly repo: IncomesRepository,
    private readonly prisma: PrismaService,
    private readonly accounts: AccountsService,
  ) {}

  private async assertAccountInWorkspace(accountId: string, ctx: WorkspaceContext) {
    const acc = await this.prisma.account.findFirst({
      where: { id: accountId, userId: ctx.ownerUserId, workspaceId: ctx.workspaceId },
    });
    if (!acc) throw new BadRequestException('Account not in this workspace');
    return acc;
  }

  create(ctx: WorkspaceContext, dto: CreateIncomeDto) {
    assertWorkspacePermission(ctx.role, 'expense:create');
    const ledgerUserId = ctx.ownerUserId;
    return this.prisma.$transaction(async (tx) => {
      await this.assertAccountInWorkspace(dto.accountId, ctx);
      const row = await tx.income.create({
        data: {
          userId: ledgerUserId,
          amount: dto.amount,
          source: dto.source,
          date: new Date(dto.date),
          note: dto.note?.trim() || null,
          accountId: dto.accountId,
        },
        include: { account: true },
      });
      await this.accounts.applyIncomeCreatedTx(tx, ledgerUserId, {
        accountId: row.accountId,
        amount: row.amount,
      });
      return serializeIncome(row);
    });
  }

  findAll(ctx: WorkspaceContext, query: ListIncomeDto) {
    assertWorkspacePermission(ctx.role, 'expense:read');
    const where: Prisma.IncomeWhereInput = {
      ...(query.source ? { source: query.source } : {}),
      ...(query.accountId ? { accountId: query.accountId } : {}),
    };
    if (query.startDate || query.endDate) {
      where.date = {
        ...(query.startDate ? { gte: new Date(query.startDate) } : {}),
        ...(query.endDate ? { lte: new Date(query.endDate) } : {}),
      };
    }
    return this.repo
      .findManyForWorkspace(ctx.ownerUserId, ctx.workspaceId, where)
      .then((rows) => rows.map(serializeIncome));
  }

  async findOne(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, 'expense:read');
    const row = await this.repo.findOneForWorkspace(ctx.ownerUserId, ctx.workspaceId, id);
    if (!row) throw new NotFoundException('Income not found');
    return serializeIncome(row);
  }

  async update(ctx: WorkspaceContext, id: string, dto: UpdateIncomeDto) {
    assertWorkspacePermission(ctx.role, 'expense:update');
    const ledgerUserId = ctx.ownerUserId;
    if (dto.accountId !== undefined) {
      await this.assertAccountInWorkspace(dto.accountId, ctx);
    }
    return this.prisma.$transaction(async (tx) => {
      const before = await tx.income.findFirst({
        where: { id, userId: ledgerUserId, account: { workspaceId: ctx.workspaceId } },
      });
      if (!before) throw new NotFoundException('Income not found');
      await this.accounts.applyIncomeRemovedTx(tx, ledgerUserId, {
        accountId: before.accountId,
        amount: before.amount,
      });
      const data: Prisma.IncomeUpdateInput = {};
      if (dto.amount !== undefined) data.amount = dto.amount;
      if (dto.source !== undefined) data.source = dto.source;
      if (dto.date !== undefined) data.date = new Date(dto.date);
      if (dto.note !== undefined) data.note = dto.note?.trim() || null;
      if (dto.accountId !== undefined) data.account = { connect: { id: dto.accountId } };
      const after = await tx.income.update({
        where: { id },
        data,
        include: { account: true },
      });
      await this.accounts.applyIncomeCreatedTx(tx, ledgerUserId, {
        accountId: after.accountId,
        amount: after.amount,
      });
      return serializeIncome(after);
    });
  }

  async remove(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, 'expense:delete');
    const ledgerUserId = ctx.ownerUserId;
    return this.prisma.$transaction(async (tx) => {
      const row = await tx.income.findFirst({
        where: { id, userId: ledgerUserId, account: { workspaceId: ctx.workspaceId } },
      });
      if (!row) throw new NotFoundException('Income not found');
      await this.accounts.applyIncomeRemovedTx(tx, ledgerUserId, {
        accountId: row.accountId,
        amount: row.amount,
      });
      await tx.income.delete({ where: { id } });
      return { deleted: true };
    });
  }
}
