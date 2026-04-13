import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminTransactionsService } from './admin-transactions.service';
import { AdminPatchExpenseDto } from './dto/admin-patch-expense.dto';
import { AdminPatchIncomeDto } from './dto/admin-patch-income.dto';
import { AdminRequestUser } from './types/admin-request-user';

@Controller('admin/transactions')
@UseGuards(AdminJwtAuthGuard)
export class AdminTransactionsController {
  constructor(private readonly tx: AdminTransactionsService) {}

  @Get()
  list(
    @Query('userId') userId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('categoryId') categoryId?: string,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.tx.list({
      userId,
      from,
      to,
      categoryId,
      skip: skip ? parseInt(skip, 10) : undefined,
      take: take ? parseInt(take, 10) : undefined,
    });
  }

  @Patch('expenses/:id')
  patchExpense(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
    @Body() body: AdminPatchExpenseDto,
  ) {
    return this.tx.patchExpense(req.user.adminId, id, body);
  }

  @Delete('expenses/:id')
  deleteExpense(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
  ) {
    return this.tx.deleteExpense(req.user.adminId, id);
  }

  @Patch('incomes/:id')
  patchIncome(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
    @Body() body: AdminPatchIncomeDto,
  ) {
    return this.tx.patchIncome(req.user.adminId, id, body);
  }

  @Delete('incomes/:id')
  deleteIncome(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
  ) {
    return this.tx.deleteIncome(req.user.adminId, id);
  }
}
