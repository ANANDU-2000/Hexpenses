import { InvestmentKind } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateInvestmentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  name!: string;

  @IsEnum(InvestmentKind)
  kind!: InvestmentKind;

  @Type(() => Number)
  @IsNumber()
  investedAmount!: number;

  @Type(() => Number)
  @IsNumber()
  currentValue!: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  note?: string;
}
