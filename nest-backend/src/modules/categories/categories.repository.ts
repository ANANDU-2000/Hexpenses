import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CategoriesRepository {
  constructor(private readonly prisma: PrismaService) {}

  findManyByUser(userId: string) {
    return this.prisma.category.findMany({
      where: { userId },
      include: { subCategoryRows: true },
      orderBy: { name: 'asc' },
    });
  }

  createCategory(data: Prisma.CategoryUncheckedCreateInput) {
    return this.prisma.category.create({
      data,
      include: { subCategoryRows: true },
    });
  }

  createSubCategory(data: Prisma.SubCategoryUncheckedCreateInput) {
    return this.prisma.subCategory.create({ data });
  }

  findCategoryForUser(userId: string, categoryId: string) {
    return this.prisma.category.findFirst({ where: { id: categoryId, userId } });
  }
}
