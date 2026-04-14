import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { EntityKind, Prisma } from "@prisma/client";
import { normalizeEntityNameKey } from "../../common/utils/normalize-name-key";
import { PrismaService } from "../../prisma/prisma.service";
import { WorkspaceContext } from "../workspaces/workspace.types";
import { assertWorkspacePermission } from "../workspaces/workspace-permissions";
import {
  serializeExpenseTypeDef,
  serializeSpendEntity,
} from "../../common/serialize-ledger";

@Injectable()
export class DimensionsService {
  constructor(private readonly prisma: PrismaService) {}

  async listExpenseTypes(
    ctx: WorkspaceContext,
    subCategoryId: string,
  ) {
    assertWorkspacePermission(ctx.role, "category:read");
    const sub = await this.prisma.subCategory.findFirst({
      where: { id: subCategoryId, category: { userId: ctx.ownerUserId } },
    });
    if (!sub) throw new NotFoundException("Subcategory not found");
    const rows = await this.prisma.expenseTypeDef.findMany({
      where: { subCategoryId },
      orderBy: [{ sortOrder: "asc" }, { name: "asc" }],
    });
    return rows.map(serializeExpenseTypeDef);
  }

  async createExpenseType(
    ctx: WorkspaceContext,
    subCategoryId: string,
    name: string,
  ) {
    assertWorkspacePermission(ctx.role, "category:create");
    const sub = await this.prisma.subCategory.findFirst({
      where: { id: subCategoryId, category: { userId: ctx.ownerUserId } },
      include: { category: true },
    });
    if (!sub) throw new NotFoundException("Subcategory not found");
    const trimmed = name.trim().replace(/\s+/g, " ");
    if (!trimmed) throw new BadRequestException("Name is required");
    const nameKey = normalizeEntityNameKey(trimmed);
    const dup = await this.prisma.expenseTypeDef.findFirst({
      where: { subCategoryId, nameKey },
    });
    if (dup) {
      throw new ConflictException({
        message: "A type with this name already exists",
        existingId: dup.id,
      });
    }
    const maxSort = await this.prisma.expenseTypeDef.aggregate({
      where: { subCategoryId },
      _max: { sortOrder: true },
    });
    const row = await this.prisma.expenseTypeDef.create({
      data: {
        userId: ctx.ownerUserId,
        subCategoryId,
        name: trimmed,
        nameKey,
        sortOrder: (maxSort._max.sortOrder ?? -1) + 1,
      },
    });
    return serializeExpenseTypeDef(row);
  }

  async reorderExpenseTypes(
    ctx: WorkspaceContext,
    subCategoryId: string,
    orderedIds: string[],
  ) {
    assertWorkspacePermission(ctx.role, "category:create");
    const sub = await this.prisma.subCategory.findFirst({
      where: { id: subCategoryId, category: { userId: ctx.ownerUserId } },
    });
    if (!sub) throw new NotFoundException("Subcategory not found");
    const existing = await this.prisma.expenseTypeDef.findMany({
      where: { subCategoryId },
      select: { id: true },
    });
    const set = new Set(existing.map((e) => e.id));
    if (orderedIds.length !== set.size) {
      throw new BadRequestException("orderedIds must include each type exactly once");
    }
    for (const id of orderedIds) {
      if (!set.has(id)) throw new BadRequestException("Unknown type id");
    }
    await this.prisma.$transaction(
      orderedIds.map((id, i) =>
        this.prisma.expenseTypeDef.update({
          where: { id },
          data: { sortOrder: i },
        }),
      ),
    );
    return { ok: true };
  }

  async deleteExpenseType(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, "category:create");
    const row = await this.prisma.expenseTypeDef.findFirst({
      where: { id, userId: ctx.ownerUserId },
    });
    if (!row) throw new NotFoundException("Type not found");
    const n = await this.prisma.expense.count({
      where: { expenseTypeId: id },
    });
    if (n > 0) {
      throw new BadRequestException(
        "Cannot delete: expenses reference this type",
      );
    }
    await this.prisma.expenseTypeDef.delete({ where: { id } });
    return { deleted: true };
  }

  async listSpendEntities(
    ctx: WorkspaceContext,
    query: { categoryId?: string; subCategoryId?: string },
  ) {
    assertWorkspacePermission(ctx.role, "category:read");
    const where: Prisma.SpendEntityWhereInput = {
      userId: ctx.ownerUserId,
      workspaceId: ctx.workspaceId,
    };
    if (query.subCategoryId) where.subCategoryId = query.subCategoryId;
    else if (query.categoryId) where.categoryId = query.categoryId;
    const rows = await this.prisma.spendEntity.findMany({
      where,
      orderBy: [{ name: "asc" }],
    });
    return rows.map(serializeSpendEntity);
  }

  async createSpendEntity(
    ctx: WorkspaceContext,
    dto: {
      categoryId: string;
      subCategoryId: string;
      name: string;
      kind?: EntityKind;
      vehicleId?: string | null;
    },
  ) {
    assertWorkspacePermission(ctx.role, "category:create");
    const sub = await this.prisma.subCategory.findFirst({
      where: {
        id: dto.subCategoryId,
        categoryId: dto.categoryId,
        category: { userId: ctx.ownerUserId },
      },
    });
    if (!sub) throw new NotFoundException("Subcategory not found for category");
    const trimmed = dto.name.trim().replace(/\s+/g, " ");
    if (!trimmed) throw new BadRequestException("Name is required");
    const nameKey = normalizeEntityNameKey(trimmed);
    const dup = await this.prisma.spendEntity.findFirst({
      where: { subCategoryId: dto.subCategoryId, nameKey },
    });
    if (dup) {
      throw new ConflictException({
        message: "An entity with this name already exists here",
        existingId: dup.id,
      });
    }
    let vehicleId: string | null | undefined = dto.vehicleId;
    if (vehicleId) {
      const v = await this.prisma.vehicle.findFirst({
        where: { id: vehicleId, userId: ctx.ownerUserId },
      });
      if (!v) throw new BadRequestException("Invalid vehicle");
      const taken = await this.prisma.spendEntity.findFirst({
        where: { vehicleId },
      });
      if (taken) throw new ConflictException("Vehicle already linked to an entity");
    }
    const row = await this.prisma.spendEntity.create({
      data: {
        userId: ctx.ownerUserId,
        workspaceId: ctx.workspaceId,
        categoryId: dto.categoryId,
        subCategoryId: dto.subCategoryId,
        name: trimmed,
        nameKey,
        kind: dto.kind ?? EntityKind.other,
        vehicleId: vehicleId ?? null,
      },
    });
    return serializeSpendEntity(row);
  }

  async deleteSpendEntity(ctx: WorkspaceContext, id: string) {
    assertWorkspacePermission(ctx.role, "category:create");
    const row = await this.prisma.spendEntity.findFirst({
      where: { id, userId: ctx.ownerUserId, workspaceId: ctx.workspaceId },
    });
    if (!row) throw new NotFoundException("Entity not found");
    const n = await this.prisma.expense.count({ where: { spendEntityId: id } });
    if (n > 0) {
      throw new BadRequestException(
        "Cannot delete: expenses reference this entity",
      );
    }
    await this.prisma.spendEntity.delete({ where: { id } });
    return { deleted: true };
  }

  async reorderSubcategories(
    ctx: WorkspaceContext,
    categoryId: string,
    orderedIds: string[],
  ) {
    assertWorkspacePermission(ctx.role, "category:create");
    const cat = await this.prisma.category.findFirst({
      where: { id: categoryId, userId: ctx.ownerUserId },
    });
    if (!cat) throw new NotFoundException("Category not found");
    const existing = await this.prisma.subCategory.findMany({
      where: { categoryId },
      select: { id: true },
    });
    const set = new Set(existing.map((e) => e.id));
    if (orderedIds.length !== set.size) {
      throw new BadRequestException(
        "orderedIds must list each subcategory exactly once",
      );
    }
    for (const id of orderedIds) {
      if (!set.has(id)) throw new BadRequestException("Unknown subcategory id");
    }
    await this.prisma.$transaction(
      orderedIds.map((id, i) =>
        this.prisma.subCategory.update({
          where: { id },
          data: { sortOrder: i },
        }),
      ),
    );
    return { ok: true };
  }
}
