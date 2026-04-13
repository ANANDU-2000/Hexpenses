import { IsString, MinLength } from 'class-validator';

export class AdminUpsertSettingDto {
  @IsString()
  @MinLength(1)
  key!: string;

  @IsString()
  value!: string;
}
