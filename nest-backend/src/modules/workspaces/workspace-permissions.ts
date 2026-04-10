import { ForbiddenException } from '@nestjs/common';
import { WorkspaceRole } from '@prisma/client';

export type WorkspaceAction =
  | 'expense:read'
  | 'expense:create'
  | 'expense:update'
  | 'expense:delete'
  | 'account:read'
  | 'account:create'
  | 'account:transfer'
  | 'category:read'
  | 'category:create'
  | 'budget:read'
  | 'budget:write'
  | 'workspace:read'
  | 'workspace:invite'
  | 'workspace:remove_member'
  | 'workspace:update_member';

const BY_ROLE: Record<WorkspaceRole, Set<WorkspaceAction>> = {
  [WorkspaceRole.owner]: new Set([
    'expense:read',
    'expense:create',
    'expense:update',
    'expense:delete',
    'account:read',
    'account:create',
    'account:transfer',
    'category:read',
    'category:create',
    'budget:read',
    'budget:write',
    'workspace:read',
    'workspace:invite',
    'workspace:remove_member',
    'workspace:update_member',
  ]),
  [WorkspaceRole.manager]: new Set([
    'expense:read',
    'expense:create',
    'expense:update',
    'expense:delete',
    'account:read',
    'account:create',
    'account:transfer',
    'category:read',
    'category:create',
    'budget:read',
    'budget:write',
    'workspace:read',
    'workspace:invite',
  ]),
  [WorkspaceRole.viewer]: new Set([
    'expense:read',
    'account:read',
    'category:read',
    'budget:read',
    'workspace:read',
  ]),
};

export function canWorkspace(role: WorkspaceRole, action: WorkspaceAction): boolean {
  return BY_ROLE[role]?.has(action) ?? false;
}

export function assertWorkspacePermission(role: WorkspaceRole, action: WorkspaceAction): void {
  if (!canWorkspace(role, action)) {
    throw new ForbiddenException(`Missing permission: ${action}`);
  }
}

/** Managers may only invite viewers (no privilege escalation). */
export function assertInviteRoleAllowed(actorRole: WorkspaceRole, targetRole: WorkspaceRole): void {
  if (actorRole === WorkspaceRole.owner) return;
  if (actorRole === WorkspaceRole.manager && targetRole === WorkspaceRole.viewer) return;
  throw new ForbiddenException('You cannot grant this role');
}
