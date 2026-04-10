import { IncomeSource } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';

export class ListIncomeDto {
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsEnum(IncomeSource)
  source?: IncomeSource;

  @IsOptional()
  @IsString()
  accountId?: string;
}
