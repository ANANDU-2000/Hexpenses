import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';
import { Frequency, RecurringMode } from '@prisma/client';

export class CreateRecurringDto {
  @Type(() => Number)
  @IsNumber()
  amount!: number;

  @IsEnum(Frequency)
  frequency!: Frequency;

  @IsOptional()
  @IsEnum(RecurringMode)
  mode?: RecurringMode;

  @IsDateString()
  nextDate!: string;

  @IsString()
  categoryId!: string;

  @IsOptional()
  @IsString()
  accountId?: string;

  @IsString()
  title!: string;

  @IsOptional()
  @IsString()
  note?: string;
}
