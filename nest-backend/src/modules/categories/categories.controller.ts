import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

import { assertWorkspacePermission } from '../workspaces/workspace-permissions';

import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';

import { RequestWithWorkspace } from '../workspaces/workspace.types';

import { CategoriesService } from './categories.service';

import { CreateCategoryDto } from './dto/create-category.dto';

import { CreateSubcategoryDto } from './dto/create-subcategory.dto';



@Controller('categories')

@UseGuards(JwtAuthGuard, WorkspaceContextGuard)

export class CategoriesController {

  constructor(private readonly categories: CategoriesService) {}



  @Get()

  findAll(@Req() req: RequestWithWorkspace) {

    assertWorkspacePermission(req.workspaceContext.role, 'category:read');

    return this.categories.findAll(req.workspaceContext.ownerUserId);

  }



  @Post()

  create(@Req() req: RequestWithWorkspace, @Body() dto: CreateCategoryDto) {

    assertWorkspacePermission(req.workspaceContext.role, 'category:create');

    return this.categories.createCategory(req.workspaceContext.ownerUserId, dto);

  }



  @Post(':categoryId/subcategories')

  createSub(

    @Req() req: RequestWithWorkspace,

    @Param('categoryId') categoryId: string,

    @Body() dto: CreateSubcategoryDto,

  ) {

    assertWorkspacePermission(req.workspaceContext.role, 'category:create');

    return this.categories.createSubcategory(req.workspaceContext.ownerUserId, categoryId, dto);

  }

}

