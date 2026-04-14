import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { EntityKind } from "@prisma/client";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { WorkspaceContextGuard } from "../workspaces/workspace-context.guard";
import { RequestWithWorkspace } from "../workspaces/workspace.types";
import { assertWorkspacePermission } from "../workspaces/workspace-permissions";
import { DimensionsService } from "./dimensions.service";

@Controller("dimensions")
@UseGuards(JwtAuthGuard, WorkspaceContextGuard)
export class DimensionsController {
  constructor(private readonly dimensions: DimensionsService) {}

  @Get("expense-types")
  listTypes(
    @Req() req: RequestWithWorkspace,
    @Query("subCategoryId") subCategoryId: string,
  ) {
    assertWorkspacePermission(req.workspaceContext.role, "category:read");
    return this.dimensions.listExpenseTypes(req.workspaceContext, subCategoryId);
  }

  @Post("expense-types")
  createType(
    @Req() req: RequestWithWorkspace,
    @Body()
    body: { subCategoryId: string; name: string },
  ) {
    return this.dimensions.createExpenseType(
      req.workspaceContext,
      body.subCategoryId,
      body.name,
    );
  }

  @Post("expense-types/reorder")
  reorderTypes(
    @Req() req: RequestWithWorkspace,
    @Body() body: { subCategoryId: string; orderedIds: string[] },
  ) {
    return this.dimensions.reorderExpenseTypes(
      req.workspaceContext,
      body.subCategoryId,
      body.orderedIds,
    );
  }

  @Delete("expense-types/:id")
  deleteType(@Req() req: RequestWithWorkspace, @Param("id") id: string) {
    return this.dimensions.deleteExpenseType(req.workspaceContext, id);
  }

  @Get("entities")
  listEntities(
    @Req() req: RequestWithWorkspace,
    @Query("categoryId") categoryId?: string,
    @Query("subCategoryId") subCategoryId?: string,
  ) {
    return this.dimensions.listSpendEntities(req.workspaceContext, {
      categoryId,
      subCategoryId,
    });
  }

  @Post("entities")
  createEntity(
    @Req() req: RequestWithWorkspace,
    @Body()
    body: {
      categoryId: string;
      subCategoryId: string;
      name: string;
      kind?: EntityKind;
      vehicleId?: string | null;
    },
  ) {
    return this.dimensions.createSpendEntity(req.workspaceContext, body);
  }

  @Delete("entities/:id")
  deleteEntity(@Req() req: RequestWithWorkspace, @Param("id") id: string) {
    return this.dimensions.deleteSpendEntity(req.workspaceContext, id);
  }

  @Post("subcategories/reorder")
  reorderSubs(
    @Req() req: RequestWithWorkspace,
    @Body() body: { categoryId: string; orderedIds: string[] },
  ) {
    return this.dimensions.reorderSubcategories(
      req.workspaceContext,
      body.categoryId,
      body.orderedIds,
    );
  }
}
