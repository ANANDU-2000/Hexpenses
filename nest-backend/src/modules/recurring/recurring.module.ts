import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { RecurringController } from './recurring.controller';
import { RecurringService } from './recurring.service';
import { QueueModule } from '../../queue/queue.module';

@Module({
  imports: [QueueModule, AccountsModule, NotificationsModule],
  controllers: [RecurringController],
  providers: [RecurringService],
})
export class RecurringModule {}
