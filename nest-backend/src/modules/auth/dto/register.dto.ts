import { IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  name!: string;

  /** Optional when using email + password (email is the primary identifier). */
  @IsOptional()
  @IsString()
  @MinLength(5)
  phone?: string;

  /** Optional when using mobile + password. */
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsOptional()
  @IsIn(['INR', 'AED', 'SAR'])
  currency?: string;

  @IsOptional()
  @IsIn(['owner', 'manager', 'family'])
  role?: string;
}
