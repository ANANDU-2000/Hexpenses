import { IsEnum } from 'class-validator';
import { AppUserStatus } from '@prisma/client';

export class AdminUserStatusDto {
  @IsEnum(AppUserStatus)
  status!: AppUserStatus;
}
