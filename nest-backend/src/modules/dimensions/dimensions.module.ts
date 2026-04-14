import { Module } from "@nestjs/common";
import { PrismaModule } from "../../prisma/prisma.module";
import { WorkspacesModule } from "../workspaces/workspaces.module";
import { DimensionsController } from "./dimensions.controller";
import { DimensionsService } from "./dimensions.service";

@Module({
  imports: [PrismaModule, WorkspacesModule],
  controllers: [DimensionsController],
  providers: [DimensionsService],
  exports: [DimensionsService],
})
export class DimensionsModule {}
