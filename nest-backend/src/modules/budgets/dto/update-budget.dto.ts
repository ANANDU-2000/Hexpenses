import { Type } from 'class-transformer';
import { IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';

export class UpdateBudgetDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  limit?: number;

  @IsOptional()
  @IsInt()
  @Min(200001)
  @Max(209912)
  yearMonth?: number;
}
