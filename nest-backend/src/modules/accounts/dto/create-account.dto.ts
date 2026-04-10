import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';
import { AccountType } from '@prisma/client';

export class CreateAccountDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @IsEnum(AccountType)
  type!: AccountType;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  initialBalance?: number;
}
