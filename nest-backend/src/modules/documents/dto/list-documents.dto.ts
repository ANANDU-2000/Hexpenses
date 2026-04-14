import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class ListDocumentsDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  q?: string;

  @IsOptional()
  @IsIn(['bill', 'insurance'])
  type?: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  tag?: string;

  @IsOptional()
  @IsString()
  expenseId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  limit?: number;
}
