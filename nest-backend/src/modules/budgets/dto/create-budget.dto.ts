import { Type } from 'class-transformer';
import { IsNumber, IsOptional, IsString, Matches, Min } from 'class-validator';

export class CreateBudgetDto {
  @IsString()
  categoryId!: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  limit!: number;

  /** Calendar month `YYYY-MM` (e.g. 2026-04). Omit = current UTC month. */
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{1,2}$/)
  month?: string;
}

export class ListBudgetDto {
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{1,2}$/)
  month?: string;
}
