import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { WorkspaceRole } from '@prisma/client';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { assertWorkspacePermission } from './workspace-permissions';
import { CreateWorkspaceDto } from './dto/create-workspace.dto';
import {
  AcceptWorkspaceInviteDto,
  AddMemberDto,
  UpdateMemberRoleDto,
  WorkspaceInviteDto,
} from './dto/workspace-invite.dto';
import { WorkspacesService } from './workspaces.service';

@Controller('workspaces')
@UseGuards(JwtAuthGuard)
export class WorkspacesController {
  constructor(private readonly workspaces: WorkspacesService) {}

  @Get()
  list(@Req() req: { user: { userId: string } }) {
    return this.workspaces.listForUser(req.user.userId);
  }

  @Post()
  create(@Req() req: { user: { userId: string } }, @Body() dto: CreateWorkspaceDto) {
    return this.workspaces.createWorkspace(req.user.userId, dto.name);
  }

  @Post('invites/accept')
  accept(@Req() req: { user: { userId: string } }, @Body() dto: AcceptWorkspaceInviteDto) {
    return this.workspaces.acceptInvite(req.user.userId, dto.token);
  }

  @Post(':workspaceId/invites')
  async invite(
    @Req() req: { user: { userId: string } },
    @Param('workspaceId') workspaceId: string,
    @Body() dto: WorkspaceInviteDto,
  ) {
    const ctx = await this.workspaces.resolveContext(req.user.userId, workspaceId);
    assertWorkspacePermission(ctx.role, 'workspace:invite');
    const role = dto.role ?? WorkspaceRole.viewer;
    return this.workspaces.createInvite(ctx, dto.email, role);
  }

  @Post(':workspaceId/members')
  async addMember(
    @Req() req: { user: { userId: string } },
    @Param('workspaceId') workspaceId: string,
    @Body() dto: AddMemberDto,
  ) {
    const ctx = await this.workspaces.resolveContext(req.user.userId, workspaceId);
    assertWorkspacePermission(ctx.role, 'workspace:invite');
    return this.workspaces.addMemberDirect(ctx, dto.email, dto.role);
  }

  @Delete(':workspaceId/members/:memberUserId')
  async removeMember(
    @Req() req: { user: { userId: string } },
    @Param('workspaceId') workspaceId: string,
    @Param('memberUserId') memberUserId: string,
  ) {
    const ctx = await this.workspaces.resolveContext(req.user.userId, workspaceId);
    assertWorkspacePermission(ctx.role, 'workspace:remove_member');
    return this.workspaces.removeMember(ctx, memberUserId);
  }

  @Patch(':workspaceId/members/:memberUserId')
  async patchMemberRole(
    @Req() req: { user: { userId: string } },
    @Param('workspaceId') workspaceId: string,
    @Param('memberUserId') memberUserId: string,
    @Body() dto: UpdateMemberRoleDto,
  ) {
    const ctx = await this.workspaces.resolveContext(req.user.userId, workspaceId);
    assertWorkspacePermission(ctx.role, 'workspace:update_member');
    return this.workspaces.updateMemberRole(ctx, memberUserId, dto.role);
  }
}
