import { Module } from '@nestjs/common';
import { WorkspaceContextGuard } from './workspace-context.guard';
import { WorkspacesController } from './workspaces.controller';
import { WorkspacesService } from './workspaces.service';

@Module({
  controllers: [WorkspacesController],
  providers: [WorkspacesService, WorkspaceContextGuard],
  exports: [WorkspacesService, WorkspaceContextGuard],
})
export class WorkspacesModule {}
