import { IsArray, IsIn, IsOptional, IsString, MinLength } from 'class-validator';
import { NotificationCategory } from '@prisma/client';

export class AdminSendNotificationDto {
  @IsString()
  @MinLength(1)
  title!: string;

  @IsString()
  @MinLength(1)
  message!: string;

  /** info / alert → system category; reminder → recurring */
  @IsIn(['info', 'alert', 'reminder'])
  type!: 'info' | 'alert' | 'reminder';

  /** Omit or empty = all users */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  userIds?: string[];
}

export function mapAdminNotifCategory(
  t: 'info' | 'alert' | 'reminder',
): NotificationCategory {
  if (t === 'reminder') return NotificationCategory.recurring;
  return NotificationCategory.system;
}
