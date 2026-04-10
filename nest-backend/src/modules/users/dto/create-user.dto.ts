import { IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  password?: string;

  @IsIn(['INR', 'AED', 'SAR'])
  currency!: string;

  @IsOptional()
  @IsIn(['owner', 'manager', 'family'])
  role?: string;
}
