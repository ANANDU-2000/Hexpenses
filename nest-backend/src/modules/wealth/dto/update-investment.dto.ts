import { InvestmentKind } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateInvestmentDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  name?: string;

  @IsOptional()
  @IsEnum(InvestmentKind)
  kind?: InvestmentKind;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  investedAmount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  currentValue?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  note?: string | null;
}
