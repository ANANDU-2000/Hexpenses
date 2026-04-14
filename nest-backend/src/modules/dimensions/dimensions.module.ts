import { Module } from "@nestjs/common";
import { PrismaModule } from "../../prisma/prisma.module";
import { DimensionsController } from "./dimensions.controller";
import { DimensionsService } from "./dimensions.service";

@Module({
  imports: [PrismaModule],
  controllers: [DimensionsController],
  providers: [DimensionsService],
  exports: [DimensionsService],
})
export class DimensionsModule {}
