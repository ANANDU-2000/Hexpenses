import { ExpenseTaxScheme, PaymentMode } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateExpenseDto {
  @Type(() => Number)
  @IsNumber()
  amount!: number;

  @IsString()
  categoryId!: string;

  @IsOptional()
  @IsString()
  subCategoryId?: string;

  @IsDateString()
  date!: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsString()
  vehicleId?: string;

  @IsOptional()
  @IsString()
  expenseTypeId?: string;

  @IsOptional()
  @IsString()
  spendEntityId?: string;

  @IsOptional()
  @IsEnum(PaymentMode)
  paymentMode?: PaymentMode;

  @IsOptional()
  @IsString()
  accountId?: string;

  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' || value === 1 || value === '1')
  @IsBoolean()
  taxable?: boolean;

  @IsOptional()
  @IsEnum(ExpenseTaxScheme)
  taxScheme?: ExpenseTaxScheme;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  taxAmount?: number;
}
