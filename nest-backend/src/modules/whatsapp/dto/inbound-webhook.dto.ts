import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

/** Generic payload for Twilio-style or custom bridges; adapt per provider. */
export class InboundWebhookDto {
  @IsString()
  @MinLength(4)
  providerMessageId!: string;

  @IsString()
  @MinLength(5)
  from!: string;

  @IsString()
  @MinLength(1)
  body!: string;

  @IsOptional()
  @IsIn(['twilio', 'meta'])
  provider?: 'twilio' | 'meta';
}
