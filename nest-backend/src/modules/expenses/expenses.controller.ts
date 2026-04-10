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

import { CreateExpenseDto } from './dto/create-expense.dto';

import { ListExpenseDto } from './dto/list-expense.dto';

import { UpdateExpenseDto } from './dto/update-expense.dto';

import { ExpensesService } from './expenses.service';



@Controller('expenses')

@UseGuards(JwtAuthGuard, WorkspaceContextGuard)

export class ExpensesController {

  constructor(private readonly expenses: ExpensesService) {}



  @Post()

  create(@Req() req: RequestWithWorkspace, @Body() dto: CreateExpenseDto) {

    return this.expenses.create(req.workspaceContext, dto);

  }



  @Get()

  findAll(@Req() req: RequestWithWorkspace, @Query() query: ListExpenseDto) {

    return this.expenses.findAll(req.workspaceContext, query);

  }



  @Get('ledger/summary')

  async summary(@Req() req: RequestWithWorkspace) {

    return this.expenses.ledgerSummary(req.workspaceContext);

  }



  @Get('ledger')

  ledger(@Req() req: RequestWithWorkspace, @Query() query: ListExpenseDto) {

    return this.expenses.findAll(req.workspaceContext, query);

  }



  @Get(':id')

  findOne(@Req() req: RequestWithWorkspace, @Param('id') id: string) {

    return this.expenses.findOne(req.workspaceContext, id);

  }



  @Patch(':id')

  update(

    @Req() req: RequestWithWorkspace,

    @Param('id') id: string,

    @Body() dto: UpdateExpenseDto,

  ) {

    return this.expenses.update(req.workspaceContext, id, dto);

  }



  @Delete(':id')

  remove(@Req() req: RequestWithWorkspace, @Param('id') id: string) {

    return this.expenses.remove(req.workspaceContext, id);

  }

}

