import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuditModule } from './audit/audit.module';
import { CryptoModule } from './crypto/crypto.module';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { ExpensesModule } from './modules/expenses/expenses.module';
import { RecurringModule } from './modules/recurring/recurring.module';
import { InsuranceModule } from './modules/insurance/insurance.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { ReportsModule } from './modules/reports/reports.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { DocumentsModule } from './modules/documents/documents.module';
import { AiModule } from './modules/ai/ai.module';
import { WhatsappModule } from './modules/whatsapp/whatsapp.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { IncomesModule } from './modules/incomes/incomes.module';
import { WealthModule } from './modules/wealth/wealth.module';
import { BudgetsModule } from './modules/budgets/budgets.module';
import { WorkspacesModule } from './modules/workspaces/workspaces.module';
import { QueueModule } from './queue/queue.module';
import { TransformResponseInterceptor } from './common/interceptors/transform-response.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuditModule,
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,
        limit: 120,
      },
    ]),
    ScheduleModule.forRoot(),
    CryptoModule,
    PrismaModule,
    HealthModule,
    QueueModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    AccountsModule,
    IncomesModule,
    WealthModule,
    BudgetsModule,
    WorkspacesModule,
    ExpensesModule,
    RecurringModule,
    InsuranceModule,
    VehiclesModule,
    ReportsModule,
    NotificationsModule,
    DocumentsModule,
    AiModule,
    WhatsappModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: TransformResponseInterceptor },
  ],
})
export class AppModule {}
