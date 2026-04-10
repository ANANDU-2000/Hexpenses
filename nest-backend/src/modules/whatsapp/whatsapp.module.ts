import { Module } from '@nestjs/common';
import { QueueModule } from '../../queue/queue.module';
import { WhatsappController } from './whatsapp.controller';
import { WhatsappDigestService } from './whatsapp-digest.service';
import { WhatsappOutboundService } from './whatsapp-outbound.service';
import { WhatsappService } from './whatsapp.service';

@Module({
  imports: [QueueModule],
  controllers: [WhatsappController],
  providers: [WhatsappService, WhatsappOutboundService, WhatsappDigestService],
  exports: [WhatsappService, WhatsappOutboundService],
})
export class WhatsappModule {}
