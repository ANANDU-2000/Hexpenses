import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { PrismaModule } from '../../prisma/prisma.module';
import { AdminActivityService } from './admin-activity.service';
import { AdminAuthController } from './admin-auth.controller';
import { AdminAuthService } from './admin-auth.service';
import { AdminBudgetsController } from './admin-budgets.controller';
import { AdminBudgetsService } from './admin-budgets.service';
import { AdminDashboardController } from './admin-dashboard.controller';
import { AdminDashboardService } from './admin-dashboard.service';
import { AdminDocumentsController } from './admin-documents.controller';
import { AdminDocumentsService } from './admin-documents.service';
import { AdminExportController } from './admin-export.controller';
import { AdminJwtStrategy } from './admin-jwt.strategy';
import { AdminNotificationsController } from './admin-notifications.controller';
import { AdminNotificationsService } from './admin-notifications.service';
import { AdminSettingsController } from './admin-settings.controller';
import { AdminSettingsService } from './admin-settings.service';
import { AdminTransactionsController } from './admin-transactions.controller';
import { AdminTransactionsService } from './admin-transactions.service';
import { AdminUsersController } from './admin-users.controller';
import { AdminUsersService } from './admin-users.service';

@Module({
  imports: [
    PrismaModule,
    PassportModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET', 'change-me'),
        signOptions: { expiresIn: '8h' },
      }),
    }),
  ],
  controllers: [
    AdminAuthController,
    AdminDashboardController,
    AdminUsersController,
    AdminTransactionsController,
    AdminNotificationsController,
    AdminDocumentsController,
    AdminBudgetsController,
    AdminSettingsController,
    AdminExportController,
  ],
  providers: [
    AdminJwtStrategy,
    AdminAuthService,
    AdminActivityService,
    AdminDashboardService,
    AdminUsersService,
    AdminTransactionsService,
    AdminNotificationsService,
    AdminDocumentsService,
    AdminBudgetsService,
    AdminSettingsService,
  ],
})
export class AdminModule {}
