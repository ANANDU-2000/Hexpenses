import { Injectable, NotFoundException } from '@nestjs/common';
import { CategoryType } from '@prisma/client';
import { CategoriesRepository } from './categories.repository';
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateSubcategoryDto } from './dto/create-subcategory.dto';

@Injectable()
export class CategoriesService {
  constructor(private readonly repo: CategoriesRepository) {}

  findAll(userId: string) {
    return this.repo.findManyByUser(userId);
  }

  createCategory(userId: string, dto: CreateCategoryDto) {
    return this.repo.createCategory({
      userId,
      name: dto.name,
      type: (dto.type as CategoryType | undefined) ?? CategoryType.expense,
    });
  }

  async createSubcategory(userId: string, categoryId: string, dto: CreateSubcategoryDto) {
    const cat = await this.repo.findCategoryForUser(userId, categoryId);
    if (!cat) throw new NotFoundException('Category not found');
    return this.repo.createSubCategory({ categoryId, name: dto.name });
  }
}
