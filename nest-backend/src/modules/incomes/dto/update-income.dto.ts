import { IncomeSource } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdateIncomeDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  amount?: number;

  @IsOptional()
  @IsEnum(IncomeSource)
  source?: IncomeSource;

  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsString()
  accountId?: string;

  @IsOptional()
  @IsString()
  note?: string;
}
