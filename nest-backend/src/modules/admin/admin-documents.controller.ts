import {
  Controller,
  Delete,
  Get,
  Param,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { AdminJwtAuthGuard } from './admin-jwt.guard';
import { AdminDocumentsService } from './admin-documents.service';
import { AdminRequestUser } from './types/admin-request-user';

@Controller('admin/documents')
@UseGuards(AdminJwtAuthGuard)
export class AdminDocumentsController {
  constructor(private readonly documents: AdminDocumentsService) {}

  @Get()
  list(
    @Query('userId') userId?: string,
    @Query('type') type?: string,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.documents.list({
      userId,
      type,
      skip: skip ? parseInt(skip, 10) : undefined,
      take: take ? parseInt(take, 10) : undefined,
    });
  }

  @Delete(':id')
  remove(
    @Req() req: Request & { user: AdminRequestUser },
    @Param('id') id: string,
  ) {
    return this.documents.remove(req.user.adminId, id);
  }
}
