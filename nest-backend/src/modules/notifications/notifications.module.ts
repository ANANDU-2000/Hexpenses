import { Module, forwardRef } from '@nestjs/common';
import { WhatsappModule } from '../whatsapp/whatsapp.module';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { QueueModule } from '../../queue/queue.module';

@Module({
  imports: [QueueModule, forwardRef(() => WhatsappModule)],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
