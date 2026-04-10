import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AccountType, AuditAction, CategoryType, Prisma } from '@prisma/client';
import { AuditEntity } from '../../audit/audit.types';
import { AuditService } from '../../audit/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { assertWorkspacePermission } from '../workspaces/workspace-permissions';
import { WorkspaceContext } from '../workspaces/workspace.types';

type ExpenseBalanceRow = {
  accountId: string | null;
  amount: Prisma.Decimal;
  category: { type: CategoryType };
};

@Injectable()
export class AccountsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  listForWorkspace(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, 'account:read');
    const ledgerUserId = ctx.ownerUserId;
    return this.prisma.account.findMany({
      where: { userId: ledgerUserId, workspaceId: ctx.workspaceId },
      orderBy: { name: 'asc' },
    });
  }

  /** Accounts plus rolled-up balances for the workspace ledger (bank + cash vs credit). */
  async ledgerOverview(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, 'account:read');
    const accounts = await this.listForWorkspace(ctx);
    let bankAndCash = 0;
    let creditDebt = 0;
    for (const a of accounts) {
      const b = Number(a.balance);
      if (a.type === AccountType.credit) creditDebt += b;
      else bankAndCash += b;
    }
    return {
      accounts,
      summary: {
        totalBankAndCash: bankAndCash.toFixed(2),
        totalCreditCardDebt: creditDebt.toFixed(2),
        netLiquid: (bankAndCash - creditDebt).toFixed(2),
        accountCount: accounts.length,
      },
    };
  }

  async createForWorkspace(
    ctx: WorkspaceContext,
    dto: { name: string; type: AccountType; initialBalance?: number },
  ) {
    assertWorkspacePermission(ctx.role, 'account:create');
    const ledgerUserId = ctx.ownerUserId;
    const bal = new Prisma.Decimal(dto.initialBalance ?? 0);
    const row = await this.prisma.account.create({
      data: {
        userId: ledgerUserId,
        workspaceId: ctx.workspaceId,
        name: dto.name.trim(),
        type: dto.type,
        balance: bal,
      },
    });
    this.audit.logAction({
      userId: ctx.memberUserId,
      action: AuditAction.CREATE,
      entity: AuditEntity.Account,
      entityId: row.id,
      metadata: {
        workspaceId: ctx.workspaceId,
        name: row.name,
        type: row.type,
        initialBalance: dto.initialBalance ?? 0,
      },
    });
    return row;
  }

  async transferForWorkspace(
    ctx: WorkspaceContext,
    dto: { fromAccountId: string; toAccountId: string; amount: number; note?: string },
  ) {
    assertWorkspacePermission(ctx.role, 'account:transfer');
    const ledgerUserId = ctx.ownerUserId;
    if (dto.fromAccountId === dto.toAccountId) {
      throw new BadRequestException('Cannot transfer to the same account');
    }
    const amt = new Prisma.Decimal(dto.amount);
    const transferId = await this.prisma.$transaction(async (tx) => {
      const from = await tx.account.findFirst({
        where: { id: dto.fromAccountId, userId: ledgerUserId, workspaceId: ctx.workspaceId },
      });
      const to = await tx.account.findFirst({
        where: { id: dto.toAccountId, userId: ledgerUserId, workspaceId: ctx.workspaceId },
      });
      if (!from || !to) throw new NotFoundException('Account not found');
      if (from.balance.lessThan(amt)) {
        throw new BadRequestException('Insufficient balance in source account');
      }
      await tx.account.update({
        where: { id: from.id },
        data: { balance: from.balance.minus(amt) },
      });
      await tx.account.update({
        where: { id: to.id },
        data: { balance: to.balance.plus(amt) },
      });
      const transferRow = await tx.accountTransfer.create({
        data: {
          userId: ledgerUserId,
          fromAccountId: from.id,
          toAccountId: to.id,
          amount: amt,
          note: dto.note?.trim() || null,
        },
      });
      return transferRow.id;
    });
    const overview = await this.ledgerOverview(ctx);
    this.audit.logAction({
      userId: ctx.memberUserId,
      action: AuditAction.CREATE,
      entity: AuditEntity.AccountTransfer,
      entityId: transferId,
      metadata: {
        workspaceId: ctx.workspaceId,
        fromAccountId: dto.fromAccountId,
        toAccountId: dto.toAccountId,
        amount: dto.amount,
      },
    });
    return overview;
  }

  /** Signed delta: income adds, expense subtracts. */
  signedDeltaForCategory(type: CategoryType, amount: Prisma.Decimal): Prisma.Decimal {
    return type === CategoryType.income ? amount : amount.negated();
  }

  async incrementBalanceTx(
    tx: Prisma.TransactionClient,
    userId: string,
    accountId: string,
    delta: Prisma.Decimal,
  ) {
    const acc = await tx.account.findFirst({ where: { id: accountId, userId } });
    if (!acc) throw new BadRequestException('Account not found');
    const next = acc.balance.plus(delta);
    await tx.account.update({ where: { id: accountId }, data: { balance: next } });
  }

  async applyExpenseCreatedTx(tx: Prisma.TransactionClient, userId: string, row: ExpenseBalanceRow) {
    if (!row.accountId) return;
    const delta = this.signedDeltaForCategory(row.category.type, row.amount);
    await this.incrementBalanceTx(tx, userId, row.accountId, delta);
  }

  async applyExpenseRemovedTx(tx: Prisma.TransactionClient, userId: string, row: ExpenseBalanceRow) {
    if (!row.accountId) return;
    const delta = this.signedDeltaForCategory(row.category.type, row.amount).negated();
    await this.incrementBalanceTx(tx, userId, row.accountId, delta);
  }

  async applyIncomeCreatedTx(
    tx: Prisma.TransactionClient,
    userId: string,
    row: { accountId: string; amount: Prisma.Decimal },
  ) {
    await this.incrementBalanceTx(tx, userId, row.accountId, row.amount);
  }

  async applyIncomeRemovedTx(
    tx: Prisma.TransactionClient,
    userId: string,
    row: { accountId: string; amount: Prisma.Decimal },
  ) {
    await this.incrementBalanceTx(tx, userId, row.accountId, row.amount.negated());
  }
}
