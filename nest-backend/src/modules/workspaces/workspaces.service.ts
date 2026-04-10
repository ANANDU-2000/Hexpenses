import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { WorkspaceRole } from '@prisma/client';
import { createHash, randomBytes } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { WorkspaceContext } from './workspace.types';
import { assertInviteRoleAllowed } from './workspace-permissions';

@Injectable()
export class WorkspacesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Create owned workspace + membership and attach orphan accounts/expenses (first-time setup). */
  async ensurePersonalWorkspace(userId: string): Promise<string> {
    const existing = await this.prisma.workspace.findFirst({
      where: { ownerUserId: userId },
    });
    if (existing) {
      await this.backfillWorkspaceIds(userId, existing.id);
      return existing.id;
    }
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    const ws = await this.prisma.$transaction(async (tx) => {
      const w = await tx.workspace.create({
        data: { name: `${user.name}'s workspace`, ownerUserId: userId },
      });
      await tx.workspaceMember.create({
        data: { workspaceId: w.id, userId, role: WorkspaceRole.owner },
      });
      await tx.account.updateMany({
        where: { userId, workspaceId: null },
        data: { workspaceId: w.id },
      });
      await tx.expense.updateMany({
        where: { userId, workspaceId: null },
        data: { workspaceId: w.id },
      });
      return w;
    });
    return ws.id;
  }

  async backfillWorkspaceIds(userId: string, workspaceId: string) {
    await this.prisma.account.updateMany({
      where: { userId, workspaceId: null },
      data: { workspaceId },
    });
    await this.prisma.expense.updateMany({
      where: { userId, workspaceId: null },
      data: { workspaceId },
    });
  }

  async resolveContext(userId: string, headerWorkspaceId?: string): Promise<WorkspaceContext> {
    let workspaceId = headerWorkspaceId?.trim() || '';
    if (!workspaceId) {
      const owned = await this.prisma.workspace.findFirst({
        where: { ownerUserId: userId },
        orderBy: { createdAt: 'asc' },
      });
      if (owned) {
        workspaceId = owned.id;
      } else {
        const m = await this.prisma.workspaceMember.findFirst({
          where: { userId },
          orderBy: { joinedAt: 'asc' },
        });
        if (m) workspaceId = m.workspaceId;
        else workspaceId = await this.ensurePersonalWorkspace(userId);
      }
    }

    const ws = await this.prisma.workspace.findUnique({
      where: { id: workspaceId },
    });
    if (!ws) throw new NotFoundException('Workspace not found');

    const member = await this.prisma.workspaceMember.findUnique({
      where: { workspaceId_userId: { workspaceId, userId } },
    });
    const isOwnerUser = ws.ownerUserId === userId;
    if (!member && !isOwnerUser) {
      throw new BadRequestException('You are not a member of this workspace');
    }
    if (!member && isOwnerUser) {
      await this.prisma.workspaceMember.create({
        data: { workspaceId, userId, role: WorkspaceRole.owner },
      });
    }
    const role = isOwnerUser ? WorkspaceRole.owner : member!.role;
    await this.backfillWorkspaceIds(ws.ownerUserId, workspaceId);
    return {
      workspaceId,
      ownerUserId: ws.ownerUserId,
      memberUserId: userId,
      role,
    };
  }

  async listForUser(userId: string) {
    const owned = await this.prisma.workspace.findMany({
      where: { ownerUserId: userId },
      include: {
        members: { include: { user: { select: { id: true, name: true, email: true } } } },
      },
    });
    const memberOf = await this.prisma.workspaceMember.findMany({
      where: { userId },
      include: {
        workspace: {
          include: {
            owner: { select: { id: true, name: true, email: true } },
            members: { include: { user: { select: { id: true, name: true, email: true } } } },
          },
        },
      },
    });
    return {
      owned,
      memberOf: memberOf.map((m) => ({
        workspaceId: m.workspaceId,
        role: m.role,
        workspace: m.workspace,
      })),
    };
  }

  async createWorkspace(userId: string, name: string) {
    return this.prisma.$transaction(async (tx) => {
      const w = await tx.workspace.create({
        data: { name: name.trim(), ownerUserId: userId },
      });
      await tx.workspaceMember.create({
        data: { workspaceId: w.id, userId, role: WorkspaceRole.owner },
      });
      return w;
    });
  }

  async createInvite(
    ctx: WorkspaceContext,
    emailRaw: string,
    role: WorkspaceRole,
  ): Promise<{ inviteId: string; token: string; expiresAt: Date }> {
    assertInviteRoleAllowed(ctx.role, role);
    if (ctx.role !== WorkspaceRole.owner && role !== WorkspaceRole.viewer) {
      throw new BadRequestException('Invalid invite role');
    }
    const email = emailRaw.trim().toLowerCase();
    if (!email.includes('@')) throw new BadRequestException('Invalid email');
    const user = await this.prisma.user.findFirst({
      where: { email },
    });
    if (user) {
      const exists = await this.prisma.workspaceMember.findUnique({
        where: { workspaceId_userId: { workspaceId: ctx.workspaceId, userId: user.id } },
      });
           if (exists) throw new BadRequestException('User is already a member');
    }
    const token = randomBytes(24).toString('base64url');
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const inv = await this.prisma.workspaceInvite.create({
      data: {
        workspaceId: ctx.workspaceId,
        email,
        role,
        tokenHash,
        expiresAt,
        createdById: ctx.memberUserId,
      },
    });
    return { inviteId: inv.id, token, expiresAt };
  }

  async acceptInvite(userId: string, token: string) {
    const tokenHash = createHash('sha256').update(token.trim()).digest('hex');
    const inv = await this.prisma.workspaceInvite.findUnique({
      where: { tokenHash },
      include: { workspace: true },
    });
    if (!inv || inv.expiresAt < new Date()) {
      throw new BadRequestException('Invalid or expired invite');
    }
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.email || user.email.toLowerCase() !== inv.email.toLowerCase()) {
      throw new BadRequestException('Sign in with the invited email to accept');
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.workspaceMember.upsert({
        where: { workspaceId_userId: { workspaceId: inv.workspaceId, userId } },
        create: { workspaceId: inv.workspaceId, userId, role: inv.role },
        update: { role: inv.role },
      });
      await tx.workspaceInvite.delete({ where: { id: inv.id } });
    });
    return { workspaceId: inv.workspaceId, role: inv.role };
  }

  async addMemberDirect(
    ctx: WorkspaceContext,
    emailRaw: string,
    role: WorkspaceRole,
  ) {
    assertInviteRoleAllowed(ctx.role, role);
    const email = emailRaw.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({ where: { email } });
    if (!user) {
      throw new BadRequestException('No user with this email — send an invite instead');
    }
    return this.prisma.workspaceMember.upsert({
      where: { workspaceId_userId: { workspaceId: ctx.workspaceId, userId: user.id } },
      create: { workspaceId: ctx.workspaceId, userId: user.id, role },
      update: { role },
    });
  }

  async removeMember(ctx: WorkspaceContext, targetUserId: string) {
    if (ctx.ownerUserId === targetUserId) {
      throw new BadRequestException('Cannot remove the workspace owner');
    }
    await this.prisma.workspaceMember.deleteMany({
      where: { workspaceId: ctx.workspaceId, userId: targetUserId },
    });
    return { removed: true };
  }

  async updateMemberRole(ctx: WorkspaceContext, targetUserId: string, role: WorkspaceRole) {
    if (targetUserId === ctx.ownerUserId && role !== WorkspaceRole.owner) {
      throw new BadRequestException('Cannot demote workspace owner');
    }
    if (targetUserId === ctx.ownerUserId) return { ok: true };
    return this.prisma.workspaceMember.update({
      where: { workspaceId_userId: { workspaceId: ctx.workspaceId, userId: targetUserId } },
      data: { role },
    });
  }
}
