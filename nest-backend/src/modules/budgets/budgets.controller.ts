import {

  Body,

  Controller,

  Delete,

  Get,

  Param,

  Patch,

  Post,

  Query,

  Req,

  UseGuards,

} from '@nestjs/common';

import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';

import { RequestWithWorkspace } from '../workspaces/workspace.types';

import { BudgetsService } from './budgets.service';

import { CreateBudgetDto, ListBudgetDto } from './dto/create-budget.dto';

import { UpdateBudgetDto } from './dto/update-budget.dto';



@Controller('budgets')

@UseGuards(JwtAuthGuard, WorkspaceContextGuard)

export class BudgetsController {

  constructor(private readonly budgets: BudgetsService) {}



  @Get()

  list(@Req() req: RequestWithWorkspace, @Query() query: ListBudgetDto) {

    return this.budgets.listWithStatus(req.workspaceContext, query.month);

  }



  @Post()

  create(@Req() req: RequestWithWorkspace, @Body() dto: CreateBudgetDto) {

    return this.budgets.create(req.workspaceContext, dto);

  }



  @Patch(':id')

  update(

    @Req() req: RequestWithWorkspace,

    @Param('id') id: string,

    @Body() dto: UpdateBudgetDto,

  ) {

    return this.budgets.update(req.workspaceContext, id, dto);

  }



  @Delete(':id')

  remove(@Req() req: RequestWithWorkspace, @Param('id') id: string) {

    return this.budgets.remove(req.workspaceContext, id);

  }

}

