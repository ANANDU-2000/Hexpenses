import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { WorkspacesService } from './workspaces.service';
import { WorkspaceContext } from './workspace.types';

@Injectable()
export class WorkspaceContextGuard implements CanActivate {
  constructor(private readonly workspaces: WorkspacesService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{
      user?: { userId: string };
      headers: Record<string, string | string[] | undefined>;
      workspaceContext?: WorkspaceContext;
    }>();
    const userId = req.user?.userId;
    if (!userId) return false;
    const raw = req.headers['x-workspace-id'];
    const headerId = typeof raw === 'string' ? raw : Array.isArray(raw) ? raw[0] : undefined;
    req.workspaceContext = await this.workspaces.resolveContext(userId, headerId);
    return true;
  }
}
