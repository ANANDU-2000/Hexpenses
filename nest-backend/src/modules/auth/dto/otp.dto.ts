import { IsString, Length } from 'class-validator';

export class OtpRequestDto {
  @IsString()
  mobileNumber!: string;
}

export class OtpVerifyDto {
  @IsString()
  mobileNumber!: string;

  @IsString()
  @Length(6, 6)
  otpCode!: string;
}
