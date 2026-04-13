import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminActivityService } from './admin-activity.service';
import { AdminUpsertSettingDto } from './dto/admin-setting.dto';

@Injectable()
export class AdminSettingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activity: AdminActivityService,
  ) {}

  async getAll() {
    return this.prisma.appSetting.findMany({ orderBy: { key: 'asc' } });
  }

  async upsert(adminId: string, dto: AdminUpsertSettingDto) {
    const row = await this.prisma.appSetting.upsert({
      where: { key: dto.key },
      create: { key: dto.key, value: dto.value },
      update: { value: dto.value },
    });
    await this.activity.log(adminId, 'setting.upsert', { key: dto.key });
    return row;
  }
}
