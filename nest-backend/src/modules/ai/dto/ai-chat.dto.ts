import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

class ChatTurnDto {
  @IsIn(['user', 'assistant'])
  role!: 'user' | 'assistant';

  @IsString()
  @MaxLength(8000)
  content!: string;
}

class ActionProposalDto {
  @IsIn(['create_expense', 'update_expense', 'delete_expense'])
  type!: 'create_expense' | 'update_expense' | 'delete_expense';

  @IsObject()
  payload!: Record<string, unknown>;
}

class ActionConfirmationDto {
  @ValidateNested()
  @Type(() => ActionProposalDto)
  proposal!: ActionProposalDto;

  @IsBoolean()
  approve!: boolean;
}

export class AiChatDto {
  @IsString()
  @MaxLength(4000)
  message!: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChatTurnDto)
  history?: ChatTurnDto[];

  @IsOptional()
  @IsIn(['en', 'ml', 'auto'])
  lang?: 'en' | 'ml' | 'auto';

  @IsOptional()
  @ValidateNested()
  @Type(() => ActionConfirmationDto)
  actionConfirmation?: ActionConfirmationDto;
}
