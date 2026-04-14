import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import type { Express } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { DocumentsService } from './documents.service';
import { ListDocumentsDto } from './dto/list-documents.dto';
import { UpdateDocumentDto } from './dto/update-document.dto';
import { UploadDocumentDto } from './dto/upload-document.dto';

@Controller('documents')
@UseGuards(JwtAuthGuard)
export class DocumentsController {
  constructor(private readonly documents: DocumentsService) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          cb(null, join(process.cwd(), 'uploads'));
        },
        filename: (_req, file, cb) => {
          cb(null, `${randomUUID()}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 20 * 1024 * 1024 },
    }),
  )
  async upload(
    @Req() req: { user: { userId: string } },
    @UploadedFile() file: Express.Multer.File,
    @Body() body: UploadDocumentDto,
  ) {
    if (!file) {
      throw new BadRequestException('file is required');
    }
    return this.documents.createFromUpload(
      req.user.userId,
      file,
      body.type,
      body.tags,
      body.expenseId,
    );
  }

  @Get()
  async list(@Req() req: { user: { userId: string } }, @Query() query: ListDocumentsDto) {
    const documents = await this.documents.list(req.user.userId, query);
    return { documents };
  }

  @Get(':id/file')
  async file(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ): Promise<StreamableFile> {
    const { stream, mime, downloadName } = await this.documents.openFileStream(req.user.userId, id);
    return new StreamableFile(stream, {
      type: mime,
      disposition: `inline; filename="${encodeURIComponent(downloadName)}"`,
    });
  }

  @Patch(':id')
  async patch(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
    @Body() body: UpdateDocumentDto,
  ) {
    return this.documents.updateTags(req.user.userId, id, body.tags);
  }
}
