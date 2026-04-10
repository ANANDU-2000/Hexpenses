import { WorkspaceRole } from '@prisma/client';

export type WorkspaceContext = {
  workspaceId: string;
  ownerUserId: string;
  memberUserId: string;
  role: WorkspaceRole;
};

export type RequestWithWorkspace = {
  user: { userId: string; phone?: string; email?: string; role?: string };
  workspaceContext: WorkspaceContext;
};
