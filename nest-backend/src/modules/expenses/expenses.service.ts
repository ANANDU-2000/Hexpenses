import {
  BadRequestException,
  forwardRef,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import {
  AuditAction,
  CategoryType,
  ExpenseSource,
  ExpenseTaxScheme,
  Prisma,
} from "@prisma/client";
import { AuditEntity } from "../../audit/audit.types";
import { AuditService } from "../../audit/audit.service";
import { PrismaService } from "../../prisma/prisma.service";
import { WorkspaceContext } from "../workspaces/workspace.types";
import { assertWorkspacePermission } from "../workspaces/workspace-permissions";
import { AccountsService } from "../accounts/accounts.service";
import { BudgetsService } from "../budgets/budgets.service";
import { serializeExpense } from "../../common/serialize-ledger";
import { ExpensesRepository } from "./expenses.repository";
import { CreateExpenseDto } from "./dto/create-expense.dto";
import { ListExpenseDto } from "./dto/list-expense.dto";
import { UpdateExpenseDto } from "./dto/update-expense.dto";

@Injectable()
export class ExpensesService {
  private readonly logger = new Logger(ExpensesService.name);

  constructor(
    private readonly repo: ExpensesRepository,
    private readonly prisma: PrismaService,
    private readonly accounts: AccountsService,
    private readonly audit: AuditService,
    @Inject(forwardRef(() => BudgetsService))
    private readonly budgets: BudgetsService,
  ) {}

  private async assertExpenseDimensions(
    tx: Prisma.TransactionClient,
    ledgerUserId: string,
    data: {
      categoryId: string;
      subCategoryId?: string | null;
      expenseTypeId?: string | null;
      spendEntityId?: string | null;
    },
  ) {
    if (data.expenseTypeId) {
      const et = await tx.expenseTypeDef.findFirst({
        where: { id: data.expenseTypeId, userId: ledgerUserId },
      });
      if (!et) throw new BadRequestException("Invalid expense type");
      if (
        data.subCategoryId &&
        et.subCategoryId !== data.subCategoryId
      ) {
        throw new BadRequestException(
          "Expense type must belong to the selected subcategory",
        );
      }
    }
    if (data.spendEntityId) {
      const se = await tx.spendEntity.findFirst({
        where: { id: data.spendEntityId, userId: ledgerUserId },
      });
      if (!se) throw new BadRequestException("Invalid entity");
      if (se.categoryId !== data.categoryId) {
        throw new BadRequestException("Entity must match category");
      }
      if (
        data.subCategoryId &&
        se.subCategoryId !== data.subCategoryId
      ) {
        throw new BadRequestException("Entity must match subcategory");
      }
    }
  }

  private normalizeTax(
    amount: number,
    taxable: boolean | undefined,
    taxScheme: ExpenseTaxScheme | undefined,
    taxAmount: number | undefined,
  ): {
    taxable: boolean;
    taxScheme: ExpenseTaxScheme | null;
    taxAmount: Prisma.Decimal | null;
  } {
    if (!taxable) {
      return { taxable: false, taxScheme: null, taxAmount: null };
    }
    if (taxScheme == null || taxAmount == null) {
      throw new BadRequestException(
        "taxScheme and taxAmount are required when taxable is true.",
      );
    }
    if (taxAmount < 0 || taxAmount > amount) {
      throw new BadRequestException(
        "taxAmount must be between 0 and the expense amount.",
      );
    }
    return {
      taxable: true,
      taxScheme,
      taxAmount: new Prisma.Decimal(taxAmount),
    };
  }

  private async assertAccountInWorkspace(
    accountId: string | undefined | null,
    workspaceId: string,
    ledgerUserId: string,
  ) {
    if (!accountId) return;
    const acc = await this.prisma.account.findFirst({
      where: { id: accountId, userId: ledgerUserId, workspaceId },
    });
    if (!acc) throw new BadRequestException("Account not in this workspace");
  }

  /** WhatsApp inbound: ledger owner userId; workspace from owner. */
  async createFromWhatsapp(
    userId: string,
    params: {
      amount: number;
      categoryId: string;
      date: Date;
      note: string;
      whatsappMessageId: string;
    },
  ) {
    const ws = await this.prisma.workspace.findFirst({
      where: { ownerUserId: userId },
      orderBy: { createdAt: "asc" },
    });
    return this.prisma.expense
      .create({
        data: {
          userId,
          amount: params.amount,
          categoryId: params.categoryId,
          date: params.date,
          note: params.note,
          source: ExpenseSource.whatsapp,
          whatsappMessageId: params.whatsappMessageId,
          workspaceId: ws?.id,
          enteredByUserId: userId,
        },
        include: {
          category: true,
          subCategory: true,
          expenseType: true,
          spendEntity: true,
          account: true,
          enteredBy: { select: { id: true, name: true } },
        },
      })
      .then((expense) => {
        this.audit.logAction({
          userId,
          action: AuditAction.CREATE,
          entity: AuditEntity.Expense,
          entityId: expense.id,
          metadata: {
            source: ExpenseSource.whatsapp,
            workspaceId: ws?.id ?? null,
            amount: Number(expense.amount),
            categoryId: expense.categoryId,
          },
        });
        return serializeExpense(expense);
      });
  }

  create(ctx: WorkspaceContext, dto: CreateExpenseDto) {
    assertWorkspacePermission(ctx.role, "expense:create");
    const ledgerUserId = ctx.ownerUserId;
    this.logger.debug(
      `create expense ledger=${ledgerUserId} actor=${ctx.memberUserId}`,
    );
    return this.prisma
      .$transaction(async (tx) => {
        await this.assertAccountInWorkspace(
          dto.accountId,
          ctx.workspaceId,
          ledgerUserId,
        );
        const category = await tx.category.findFirst({
          where: { id: dto.categoryId, userId: ledgerUserId },
        });
        if (!category) throw new BadRequestException("Invalid category");
        if (category.type !== CategoryType.expense) {
          throw new BadRequestException(
            "Selected category cannot be used for expenses",
          );
        }
        await this.assertExpenseDimensions(tx, ledgerUserId, {
          categoryId: dto.categoryId,
          subCategoryId: dto.subCategoryId,
          expenseTypeId: dto.expenseTypeId,
          spendEntityId: dto.spendEntityId,
        });
        const tax = this.normalizeTax(
          dto.amount,
          dto.taxable,
          dto.taxScheme,
          dto.taxAmount,
        );
        const expense = await tx.expense.create({
          data: {
            userId: ledgerUserId,
            workspaceId: ctx.workspaceId,
            enteredByUserId: ctx.memberUserId,
            amount: dto.amount,
            categoryId: dto.categoryId,
            subCategoryId: dto.subCategoryId,
            expenseTypeId: dto.expenseTypeId,
            spendEntityId: dto.spendEntityId,
            paymentMode: dto.paymentMode,
            date: new Date(dto.date),
            note: dto.note,
            vehicleId: dto.vehicleId,
            accountId: dto.accountId,
            taxable: tax.taxable,
            taxScheme: tax.taxScheme,
            taxAmount: tax.taxAmount,
          },
          include: {
            category: true,
            subCategory: true,
            expenseType: true,
            spendEntity: true,
            account: true,
            enteredBy: { select: { id: true, name: true } },
          },
        });
        if (dto.accountId) {
          await this.accounts.applyExpenseCreatedTx(tx, ledgerUserId, {
            accountId: expense.accountId,
            amount: expense.amount,
            category: expense.category,
          });
        }
        return expense;
      })
      .then((expense) => {
        this.audit.logAction({
          userId: ctx.memberUserId,
          action: AuditAction.CREATE,
          entity: AuditEntity.Expense,
          entityId: expense.id,
          metadata: {
            workspaceId: ctx.workspaceId,
            ledgerUserId,
            amount: Number(expense.amount),
            categoryId: expense.categoryId,
            accountId: expense.accountId,
          },
        });
        void this.budgets
          .notifyIfBudgetExceededForExpense(
            ledgerUserId,
            ctx.workspaceId,
            expense.categoryId,
            expense.date,
          )
          .catch((e) =>
            this.logger.warn(`budget push check: ${(e as Error).message}`),
          );
        return serializeExpense(expense);
      });
  }

  async ledgerSummary(ctx: WorkspaceContext) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const ledgerUserId = ctx.ownerUserId;
    const [expenseAgg, incomeAgg] = await Promise.all([
      this.prisma.expense.aggregate({
        where: {
          userId: ledgerUserId,
          workspaceId: ctx.workspaceId,
          category: { type: CategoryType.expense },
        },
        _sum: { amount: true },
      }),
      this.prisma.income.aggregate({
        where: {
          userId: ledgerUserId,
          account: { workspaceId: ctx.workspaceId },
        },
        _sum: { amount: true },
      }),
    ]);
    const totalExpenses = Number(expenseAgg._sum.amount ?? 0);
    const totalIncome = Number(incomeAgg._sum.amount ?? 0);
    const balance = totalIncome - totalExpenses;
    return {
      total_income: totalIncome.toFixed(2),
      total_expenses: totalExpenses.toFixed(2),
      balance: balance.toFixed(2),
    };
  }

  findAll(ctx: WorkspaceContext, query: ListExpenseDto) {
    assertWorkspacePermission(ctx.role, "expense:read");
    return this.repo
      .findManyForUser(ctx.ownerUserId, ctx.workspaceId, {
        categoryId: query.categoryId,
        subCategoryId: query.subCategoryId,
        ...(query.expenseTypeId ? { expenseTypeId: query.expenseTypeId } : {}),
        ...(query.spendEntityId ? { spendEntityId: query.spendEntityId } : {}),
        ...(query.paymentMode ? { paymentMode: query.paymentMode } : {}),
        ...(query.accountId ? { accountId: query.accountId } : {}),
        date: {
          gte: query.startDate ? new Date(query.startDate) : undefined,
          lte: query.endDate ? new Date(query.endDate) : undefined,
        },
      })
      .then((rows) => rows.map(serializeExpense));
  }

  async findOne(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, "expense:read");
    const row = await this.repo.findOneForUser(
      ctx.ownerUserId,
      ctx.workspaceId,
      id,
    );
    if (!row) throw new NotFoundException("Expense not found");
    return serializeExpense(row);
  }

  async update(ctx: WorkspaceContext, id: string, dto: UpdateExpenseDto) {
    assertWorkspacePermission(ctx.role, "expense:update");
    const ledgerUserId = ctx.ownerUserId;
    if (dto.accountId !== undefined) {
      await this.assertAccountInWorkspace(
        dto.accountId,
        ctx.workspaceId,
        ledgerUserId,
      );
    }
    return this.prisma
      .$transaction(async (tx) => {
        const before = await tx.expense.findFirst({
          where: { id, userId: ledgerUserId, workspaceId: ctx.workspaceId },
          include: { category: true },
        });
        if (!before) throw new NotFoundException("Expense not found");
        if (dto.categoryId) {
          const cat = await tx.category.findFirst({
            where: { id: dto.categoryId, userId: ledgerUserId },
          });
          if (!cat) throw new BadRequestException("Invalid category");
          if (cat.type !== CategoryType.expense) {
            throw new BadRequestException(
              "Selected category cannot be used for expenses",
            );
          }
        }
        const effCategoryId = dto.categoryId ?? before.categoryId;
        const effSub =
          dto.subCategoryId !== undefined
            ? dto.subCategoryId
            : before.subCategoryId;
        const effExpenseTypeId =
          dto.expenseTypeId !== undefined
            ? dto.expenseTypeId
            : before.expenseTypeId;
        const effSpendEntityId =
          dto.spendEntityId !== undefined
            ? dto.spendEntityId
            : before.spendEntityId;
        await this.assertExpenseDimensions(tx, ledgerUserId, {
          categoryId: effCategoryId,
          subCategoryId: effSub,
          expenseTypeId: effExpenseTypeId,
          spendEntityId: effSpendEntityId,
        });
        if (before.accountId) {
          await this.accounts.applyExpenseRemovedTx(tx, ledgerUserId, {
            accountId: before.accountId,
            amount: before.amount,
            category: before.category,
          });
        }
        const effAmount =
          dto.amount !== undefined ? dto.amount : Number(before.amount);
        let taxable = before.taxable;
        if (dto.taxable === false) taxable = false;
        else if (dto.taxable === true) taxable = true;
        let taxScheme: ExpenseTaxScheme | null | undefined =
          before.taxScheme ?? undefined;
        if (dto.taxScheme !== undefined) taxScheme = dto.taxScheme;
        let taxAmount: number | undefined =
          before.taxAmount != null ? Number(before.taxAmount) : undefined;
        if (dto.taxAmount !== undefined) taxAmount = dto.taxAmount;

        const tax = taxable
          ? this.normalizeTax(
              effAmount,
              true,
              taxScheme ?? undefined,
              taxAmount,
            )
          : { taxable: false, taxScheme: null, taxAmount: null };

        const data: Prisma.ExpenseUpdateInput = {};
        if (dto.amount !== undefined) data.amount = dto.amount;
        if (dto.categoryId !== undefined)
          data.category = { connect: { id: dto.categoryId } };
        if (dto.subCategoryId !== undefined) {
          data.subCategory = dto.subCategoryId
            ? { connect: { id: dto.subCategoryId } }
            : { disconnect: true };
        }
        if (dto.date !== undefined) data.date = new Date(dto.date);
        if (dto.note !== undefined) data.note = dto.note;
        if (dto.vehicleId !== undefined) {
          data.vehicle = dto.vehicleId
            ? { connect: { id: dto.vehicleId } }
            : { disconnect: true };
        }
        if (dto.expenseTypeId !== undefined) {
          data.expenseType = dto.expenseTypeId
            ? { connect: { id: dto.expenseTypeId } }
            : { disconnect: true };
        }
        if (dto.spendEntityId !== undefined) {
          data.spendEntity = dto.spendEntityId
            ? { connect: { id: dto.spendEntityId } }
            : { disconnect: true };
        }
        if (dto.paymentMode !== undefined) {
          data.paymentMode = dto.paymentMode;
        }
        if (dto.accountId !== undefined) {
          data.account = dto.accountId
            ? { connect: { id: dto.accountId } }
            : { disconnect: true };
        }
        data.taxable = tax.taxable;
        data.taxScheme = tax.taxScheme;
        data.taxAmount = tax.taxAmount;
        const after = await tx.expense.update({
          where: { id },
          data,
          include: {
            category: true,
            subCategory: true,
            expenseType: true,
            spendEntity: true,
            account: true,
            enteredBy: { select: { id: true, name: true } },
          },
        });
        if (after.accountId) {
          await this.accounts.applyExpenseCreatedTx(tx, ledgerUserId, {
            accountId: after.accountId,
            amount: after.amount,
            category: after.category,
          });
        }
        return {
          after,
          beforeSnapshot: {
            amount: Number(before.amount),
            categoryId: before.categoryId,
          },
          beforeCategoryId: before.categoryId,
          beforeDate: before.date,
          dto,
        };
      })
      .then(
        ({
          after,
          beforeSnapshot,
          beforeCategoryId,
          beforeDate,
          dto: patch,
        }) => {
          const changedFields = Object.entries(patch)
            .filter(([, v]) => v !== undefined)
            .map(([k]) => k);
          this.audit.logAction({
            userId: ctx.memberUserId,
            action: AuditAction.UPDATE,
            entity: AuditEntity.Expense,
            entityId: after.id,
            metadata: {
              workspaceId: ctx.workspaceId,
              ledgerUserId,
              before: beforeSnapshot,
              after: {
                amount: Number(after.amount),
                categoryId: after.categoryId,
                accountId: after.accountId,
              },
              changedFields,
            },
          });
          void this.budgets
            .notifyIfBudgetExceededForExpense(
              ledgerUserId,
              ctx.workspaceId,
              after.categoryId,
              after.date,
            )
            .catch((e) =>
              this.logger.warn(`budget push check: ${(e as Error).message}`),
            );
          if (
            beforeCategoryId !== after.categoryId ||
            beforeDate.getTime() !== after.date.getTime()
          ) {
            void this.budgets
              .notifyIfBudgetExceededForExpense(
                ledgerUserId,
                ctx.workspaceId,
                beforeCategoryId,
                beforeDate,
              )
              .catch((e) =>
                this.logger.warn(`budget push check: ${(e as Error).message}`),
              );
          }
          return serializeExpense(after);
        },
      );
  }

  async remove(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, "expense:delete");
    const ledgerUserId = ctx.ownerUserId;
    return this.prisma
      .$transaction(async (tx) => {
        const row = await tx.expense.findFirst({
          where: { id, userId: ledgerUserId, workspaceId: ctx.workspaceId },
          include: { category: true },
        });
        if (!row) throw new NotFoundException("Expense not found");
        if (row.accountId) {
          await this.accounts.applyExpenseRemovedTx(tx, ledgerUserId, {
            accountId: row.accountId,
            amount: row.amount,
            category: row.category,
          });
        }
        await tx.expense.delete({ where: { id } });
        return {
          entityId: id,
          metadata: {
            workspaceId: ctx.workspaceId,
            ledgerUserId,
            amount: Number(row.amount),
            categoryId: row.categoryId,
            accountId: row.accountId,
            expenseDate: row.date,
          },
        };
      })
      .then(({ entityId, metadata }) => {
        this.audit.logAction({
          userId: ctx.memberUserId,
          action: AuditAction.DELETE,
          entity: AuditEntity.Expense,
          entityId,
          metadata,
        });
        const catId = metadata.categoryId as string;
        const expDate = metadata.expenseDate as Date;
        void this.budgets
          .notifyIfBudgetExceededForExpense(
            ledgerUserId,
            ctx.workspaceId,
            catId,
            expDate,
          )
          .catch((e) =>
            this.logger.warn(`budget push check: ${(e as Error).message}`),
          );
        return { deleted: true };
      });
  }
}
