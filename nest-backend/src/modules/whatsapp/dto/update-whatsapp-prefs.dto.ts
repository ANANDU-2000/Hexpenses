import { IsBoolean, IsOptional, IsString, Matches } from 'class-validator';

export class UpdateWhatsappPrefsDto {
  @IsOptional()
  @IsBoolean()
  dailySummary?: boolean;

  @IsOptional()
  @IsBoolean()
  monthlyReport?: boolean;

  @IsOptional()
  @IsBoolean()
  alerts?: boolean;

  /** When set, only this linked number is updated; otherwise all links for the user. */
  @IsOptional()
  @IsString()
  @Matches(/^\+[1-9]\d{6,14}$/)
  phoneE164?: string;
}
