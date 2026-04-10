import { ArrayMaxSize, IsArray, IsString, MaxLength } from 'class-validator';

export class UpdateDocumentDto {
  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(48, { each: true })
  tags!: string[];
}
