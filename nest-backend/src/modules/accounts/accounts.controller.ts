import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';

import { RequestWithWorkspace } from '../workspaces/workspace.types';

import { AccountsService } from './accounts.service';

import { CreateAccountDto } from './dto/create-account.dto';

import { TransferDto } from './dto/transfer.dto';



@Controller('accounts')

@UseGuards(JwtAuthGuard, WorkspaceContextGuard)

export class AccountsController {

  constructor(private readonly accounts: AccountsService) {}



  @Post()

  create(@Req() req: RequestWithWorkspace, @Body() dto: CreateAccountDto) {

    return this.accounts.createForWorkspace(req.workspaceContext, dto);

  }



  @Get()

  findAll(@Req() req: RequestWithWorkspace) {

    return this.accounts.ledgerOverview(req.workspaceContext);

  }



  @Post('transfer')

  transfer(@Req() req: RequestWithWorkspace, @Body() dto: TransferDto) {

    return this.accounts.transferForWorkspace(req.workspaceContext, dto);

  }

}

