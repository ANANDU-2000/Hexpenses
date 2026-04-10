import { IsIn, IsOptional, IsString } from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsIn(['expense', 'income'])
  type?: 'expense' | 'income';
}
