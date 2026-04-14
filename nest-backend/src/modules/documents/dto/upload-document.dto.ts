import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class UploadDocumentDto {
  @IsIn(['bill', 'insurance'])
  type!: string;

  /** Comma- or semicolon-separated tags (stored lowercase). */
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  tags?: string;

  /** Link attachment to a ledger expense (same user). */
  @IsOptional()
  @IsString()
  expenseId?: string;
}
