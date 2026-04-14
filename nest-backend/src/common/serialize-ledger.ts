import type {
  Account,
  Category,
  ExpenseTypeDef,
  Prisma,
  SpendEntity,
  SubCategory,
} from '@prisma/client';

export function serializeAccount(a: Account) {
  return {
    id: a.id,
    name: a.name,
    type: a.type,
    balance: a.balance.toFixed(2),
    userId: a.userId,
    workspaceId: a.workspaceId,
    createdAt: a.createdAt.toISOString(),
    updatedAt: a.updatedAt.toISOString(),
  };
}

export function serializeCategory(c: Category) {
  return {
    id: c.id,
    name: c.name,
    nameKey: c.nameKey,
    systemKey: c.systemKey,
    sortOrder: c.sortOrder,
    type: c.type,
    userId: c.userId,
  };
}

export function serializeSubCategory(s: SubCategory) {
  return {
    id: s.id,
    name: s.name,
    nameKey: s.nameKey,
    categoryId: s.categoryId,
    sortOrder: s.sortOrder,
  };
}

export function serializeExpenseTypeDef(t: ExpenseTypeDef) {
  return {
    id: t.id,
    name: t.name,
    nameKey: t.nameKey,
    subCategoryId: t.subCategoryId,
    sortOrder: t.sortOrder,
    userId: t.userId,
  };
}

export function serializeSpendEntity(e: SpendEntity) {
  return {
    id: e.id,
    name: e.name,
    nameKey: e.nameKey,
    kind: e.kind,
    categoryId: e.categoryId,
    subCategoryId: e.subCategoryId,
    workspaceId: e.workspaceId,
    vehicleId: e.vehicleId,
    userId: e.userId,
  };
}

export type ExpenseWithRelations = Prisma.ExpenseGetPayload<{
  include: {
    category: true;
    subCategory: true;
    expenseType: true;
    spendEntity: true;
    account: true;
    enteredBy: { select: { id: true; name: true } };
  };
}>;

export function serializeExpense(e: ExpenseWithRelations) {
  return {
    id: e.id,
    amount: e.amount.toFixed(2),
    categoryId: e.categoryId,
    subCategoryId: e.subCategoryId,
    expenseTypeId: e.expenseTypeId,
    spendEntityId: e.spendEntityId,
    paymentMode: e.paymentMode,
    accountId: e.accountId,
    date: e.date.toISOString(),
    note: e.note,
    userId: e.userId,
    workspaceId: e.workspaceId,
    enteredByUserId: e.enteredByUserId,
    currency: e.currency,
    source: e.source,
    metadata: e.metadata,
    vehicleId: e.vehicleId,
    recurringExpenseId: e.recurringExpenseId,
    whatsappMessageId: e.whatsappMessageId,
    taxable: e.taxable,
    taxScheme: e.taxScheme,
    taxAmount: e.taxAmount != null ? e.taxAmount.toFixed(2) : null,
    createdAt: e.createdAt.toISOString(),
    updatedAt: e.updatedAt.toISOString(),
    category: serializeCategory(e.category),
    subCategory: e.subCategory ? serializeSubCategory(e.subCategory) : null,
    expenseType: e.expenseType ? serializeExpenseTypeDef(e.expenseType) : null,
    spendEntity: e.spendEntity ? serializeSpendEntity(e.spendEntity) : null,
    account: e.account ? serializeAccount(e.account) : null,
    enteredBy: e.enteredBy,
  };
}

export type IncomeWithAccount = Prisma.IncomeGetPayload<{ include: { account: true } }>;

export function serializeIncome(i: IncomeWithAccount) {
  return {
    id: i.id,
    amount: i.amount.toFixed(2),
    source: i.source,
    date: i.date.toISOString(),
    note: i.note,
    userId: i.userId,
    accountId: i.accountId,
    createdAt: i.createdAt.toISOString(),
    updatedAt: i.updatedAt.toISOString(),
    account: serializeAccount(i.account),
  };
}
