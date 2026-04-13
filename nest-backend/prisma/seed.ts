/**
 * Demo account for QA / local testing (see .env.example).
 * Run: npx prisma db seed   (from nest-backend, after migrate deploy)
 */
import * as bcrypt from 'bcrypt';
import {
  AccountType,
  IncomeSource,
  AiInsightStatus,
  AiInsightType,
  CategoryType,
  Frequency,
  NotificationCategory,
  NotificationChannel,
  Prisma,
  PrismaClient,
  RecurringMode,
  UserRole,
  WorkspaceRole,
} from '@prisma/client';

const prisma = new PrismaClient();

/** Email sign-in (Flutter “Sign in” tab). Display name: Usermony */
const DEMO_EMAIL = 'usermony@test.moneyflow';
const DEMO_PASSWORD = '123589srgm';
const DEMO_NAME = 'Usermony';

async function ensureDemoWorkspace(userId: string, userName: string) {
  let ws = await prisma.workspace.findFirst({ where: { ownerUserId: userId } });
  if (!ws) {
    ws = await prisma.workspace.create({
      data: { name: `${userName}'s workspace`, ownerUserId: userId },
    });
    await prisma.workspaceMember.create({
      data: { workspaceId: ws.id, userId, role: WorkspaceRole.owner },
    });
  }
  await prisma.account.updateMany({
    where: { userId, workspaceId: null },
    data: { workspaceId: ws.id },
  });
  await prisma.expense.updateMany({
    where: { userId, workspaceId: null },
    data: { workspaceId: ws.id },
  });
  return ws;
}

async function main() {
  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 12);

  const user = await prisma.user.upsert({
    where: { email: DEMO_EMAIL },
    update: {
      name: DEMO_NAME,
      passwordHash,
      deletedAt: null,
    },
    create: {
      name: DEMO_NAME,
      email: DEMO_EMAIL,
      passwordHash,
      currency: 'INR',
      role: UserRole.owner,
    },
  });

  await ensureDemoWorkspace(user.id, user.name);

  const existingCats = await prisma.category.count({ where: { userId: user.id } });
  if (existingCats > 0) {
    // eslint-disable-next-line no-console
    console.log(`Demo user ready: ${DEMO_EMAIL} / ${DEMO_PASSWORD} (data already seeded)`);
    return;
  }

  const food = await prisma.category.create({
    data: { name: 'Food', type: CategoryType.expense, userId: user.id },
  });
  await prisma.subCategory.createMany({
    data: [
      { name: 'Groceries', categoryId: food.id },
      { name: 'Dining out', categoryId: food.id },
    ],
  });

  const transport = await prisma.category.create({
    data: { name: 'Transport', type: CategoryType.expense, userId: user.id },
  });
  await prisma.subCategory.createMany({
    data: [
      { name: 'Fuel', categoryId: transport.id },
      { name: 'Transit', categoryId: transport.id },
    ],
  });

  const bills = await prisma.category.create({
    data: { name: 'Bills', type: CategoryType.expense, userId: user.id },
  });

  const ws = await prisma.workspace.findFirstOrThrow({ where: { ownerUserId: user.id } });
  const mainBank = await prisma.account.create({
    data: {
      userId: user.id,
      workspaceId: ws.id,
      name: 'Primary checking',
      type: AccountType.bank,
      balance: new Prisma.Decimal('25000'),
    },
  });
  await prisma.account.create({
    data: {
      userId: user.id,
      workspaceId: ws.id,
      name: 'Cash wallet',
      type: AccountType.cash,
      balance: new Prisma.Decimal('500'),
    },
  });

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  await prisma.expense.createMany({
    data: [
      {
        userId: user.id,
        workspaceId: ws.id,
        categoryId: food.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('85.5'),
        date: new Date(startOfMonth.getTime() + 2 * 86400000),
        note: 'Weekly groceries',
        currency: 'INR',
      },
      {
        userId: user.id,
        workspaceId: ws.id,
        categoryId: food.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('42'),
        date: new Date(startOfMonth.getTime() + 5 * 86400000),
        note: 'Cafe',
        currency: 'INR',
      },
      {
        userId: user.id,
        workspaceId: ws.id,
        categoryId: transport.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('60'),
        date: new Date(startOfMonth.getTime() + 8 * 86400000),
        note: 'Fuel',
        currency: 'INR',
      },
      {
        userId: user.id,
        workspaceId: ws.id,
        categoryId: bills.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('1200'),
        date: new Date(startOfMonth.getTime() + 10 * 86400000),
        note: 'Utilities',
        currency: 'INR',
      },
    ],
  });

  const spent = new Prisma.Decimal('1387.5');
  const demoIncome = new Prisma.Decimal('52000');
  await prisma.income.createMany({
    data: [
      {
        userId: user.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('45000'),
        source: IncomeSource.salary,
        date: new Date(startOfMonth.getTime() + 1 * 86400000),
        note: 'Demo salary',
      },
      {
        userId: user.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('6500'),
        source: IncomeSource.business,
        date: new Date(startOfMonth.getTime() + 4 * 86400000),
        note: 'Side project',
      },
      {
        userId: user.id,
        accountId: mainBank.id,
        amount: new Prisma.Decimal('500'),
        source: IncomeSource.other,
        date: new Date(startOfMonth.getTime() + 7 * 86400000),
        note: 'Cashback',
      },
    ],
  });
  await prisma.account.update({
    where: { id: mainBank.id },
    data: { balance: new Prisma.Decimal('25000').minus(spent).plus(demoIncome) },
  });

  const demoYearMonth = now.getFullYear() * 100 + (now.getMonth() + 1);
  await prisma.budget.createMany({
    data: [
      {
        userId: user.id,
        categoryId: food.id,
        amountLimit: new Prisma.Decimal('500'),
        yearMonth: demoYearMonth,
      },
      {
        userId: user.id,
        categoryId: transport.id,
        amountLimit: new Prisma.Decimal('40'),
        yearMonth: demoYearMonth,
      },
      {
        userId: user.id,
        categoryId: bills.id,
        amountLimit: new Prisma.Decimal('1500'),
        yearMonth: demoYearMonth,
      },
    ],
  });

  await prisma.investment.create({
    data: {
      userId: user.id,
      name: 'Demo ETF portfolio',
      kind: 'stock',
      investedAmount: new Prisma.Decimal('100000'),
      currentValue: new Prisma.Decimal('125000'),
    },
  });
  await prisma.liability.create({
    data: {
      userId: user.id,
      name: 'Car loan',
      balance: new Prisma.Decimal('180000'),
    },
  });

  const nextRecurring = new Date(now.getFullYear(), now.getMonth() + 1, 5);
  await prisma.recurringExpense.create({
    data: {
      userId: user.id,
      categoryId: bills.id,
      accountId: mainBank.id,
      amount: new Prisma.Decimal('99'),
      frequency: Frequency.monthly,
      mode: RecurringMode.reminder_only,
      nextDate: nextRecurring,
      title: 'Internet subscription',
      note: 'Demo recurring',
      active: true,
    },
  });

  const insEnd = new Date(now.getTime() + 180 * 86400000);
  await prisma.insurance.create({
    data: {
      userId: user.id,
      name: 'Demo Health Plan',
      type: 'health',
      premium: new Prisma.Decimal('4500'),
      startDate: new Date(now.getFullYear(), now.getMonth() - 1, 1),
      expiryDate: insEnd,
      provider: 'Sample Insurance Co',
      policyNumber: 'POL-DEMO-001',
    },
  });

  const insVehicleEnd = new Date(now.getTime() + 45 * 86400000);
  const vehicle = await prisma.vehicle.create({
    data: {
      userId: user.id,
      name: 'Demo Car',
      number: 'DEMO-001',
      vehicleType: 'car',
      purchaseDate: new Date(now.getFullYear() - 1, 2, 10),
      purchasePrice: new Prisma.Decimal('850000'),
      currentValue: new Prisma.Decimal('720000'),
      insuranceExpiryDate: insVehicleEnd,
    },
  });

  await prisma.vehicleExpense.create({
    data: {
      vehicleId: vehicle.id,
      type: 'fuel',
      amount: new Prisma.Decimal('55.25'),
      date: new Date(startOfMonth.getTime() + 6 * 86400000),
    },
  });

  await prisma.notification.create({
    data: {
      userId: user.id,
      title: 'Welcome to MoneyFlow',
      body: 'Demo data loaded — explore expenses, recurring, insurance, and vehicles.',
      channel: NotificationChannel.in_app,
      category: NotificationCategory.system,
      date: now,
      dedupeKey: 'demo-seed-welcome',
    },
  });

  await prisma.aiInsight.create({
    data: {
      userId: user.id,
      type: AiInsightType.spending_summary,
      status: AiInsightStatus.ready,
      summary:
        'Demo insight: Food and transport made up a large share of spending this month. Open Reports for a category breakdown.',
      periodStart: startOfMonth,
      periodEnd: now,
    },
  });

  // eslint-disable-next-line no-console
  console.log(`Seeded demo user: ${DEMO_EMAIL} / ${DEMO_PASSWORD} (name: ${DEMO_NAME})`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
