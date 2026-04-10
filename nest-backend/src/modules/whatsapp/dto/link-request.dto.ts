import { Matches, IsString } from 'class-validator';

export class LinkRequestDto {
  @IsString()
  @Matches(/^\+[1-9]\d{6,14}$/, { message: 'phoneE164 must be like +9198xxxxxxx' })
  phoneE164!: string;
}
