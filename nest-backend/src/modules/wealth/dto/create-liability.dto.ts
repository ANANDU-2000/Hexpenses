import { Type } from 'class-transformer';
import { IsNumber, IsString, MinLength } from 'class-validator';

export class CreateLiabilityDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @Type(() => Number)
  @IsNumber()
  balance!: number;
}
