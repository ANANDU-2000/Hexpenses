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
import { CreateIncomeDto } from './dto/create-income.dto';
import { ListIncomeDto } from './dto/list-income.dto';
import { UpdateIncomeDto } from './dto/update-income.dto';
import { IncomesService } from './incomes.service';

@Controller('incomes')
@UseGuards(JwtAuthGuard, WorkspaceContextGuard)
export class IncomesController {
  constructor(private readonly incomes: IncomesService) {}

  @Post()
  create(@Req() req: RequestWithWorkspace, @Body() dto: CreateIncomeDto) {
    return this.incomes.create(req.workspaceContext, dto);
  }

  @Get()
  findAll(@Req() req: RequestWithWorkspace, @Query() query: ListIncomeDto) {
    return this.incomes.findAll(req.workspaceContext, query);
  }

  @Get(':id')
  findOne(@Req() req: RequestWithWorkspace, @Param('id') id: string) {
    return this.incomes.findOne(req.workspaceContext, id);
  }

  @Patch(':id')
  update(
    @Req() req: RequestWithWorkspace,
    @Param('id') id: string,
    @Body() dto: UpdateIncomeDto,
  ) {
    return this.incomes.update(req.workspaceContext, id, dto);
  }

  @Delete(':id')
  remove(@Req() req: RequestWithWorkspace, @Param('id') id: string) {
    return this.incomes.remove(req.workspaceContext, id);
  }
}
