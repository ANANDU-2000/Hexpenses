import { WorkspaceRole } from '@prisma/client';
import { IsEmail, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

export class WorkspaceInviteDto {
  @IsEmail()
  email!: string;

  /** Defaults to viewer. Owners may invite managers; managers may invite viewers only. */
  @IsOptional()
  @IsEnum(WorkspaceRole)
  role?: WorkspaceRole;
}

export class AcceptWorkspaceInviteDto {
  @IsString()
  @MinLength(10)
  token!: string;
}

export class AddMemberDto {
  @IsEmail()
  email!: string;

  @IsEnum(WorkspaceRole)
  role!: WorkspaceRole;
}

export class UpdateMemberRoleDto {
  @IsEnum(WorkspaceRole)
  role!: WorkspaceRole;
}
