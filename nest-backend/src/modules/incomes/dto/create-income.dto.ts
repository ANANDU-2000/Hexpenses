import { IncomeSource } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateIncomeDto {
  @Type(() => Number)
  @IsNumber()
  amount!: number;

  @IsEnum(IncomeSource)
  source!: IncomeSource;

  @IsDateString()
  date!: string;

  @IsString()
  accountId!: string;

  @IsOptional()
  @IsString()
  note?: string;
}
