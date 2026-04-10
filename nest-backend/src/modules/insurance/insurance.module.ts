import { Module } from '@nestjs/common';
import { CryptoModule } from '../../crypto/crypto.module';
import { InsuranceController } from './insurance.controller';
import { InsuranceService } from './insurance.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [CryptoModule, NotificationsModule],
  controllers: [InsuranceController],
  providers: [InsuranceService],
  exports: [InsuranceService],
})
export class InsuranceModule {}
