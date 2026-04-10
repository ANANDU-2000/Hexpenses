import { IsString, Matches } from 'class-validator';

export class LinkConfirmDto {
  @IsString()
  @Matches(/^\+[1-9]\d{6,14}$/)
  phoneE164!: string;

  @IsString()
  @Matches(/^\d{6}$/)
  code!: string;
}
