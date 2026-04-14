import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ExpensesRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(data: Prisma.ExpenseUncheckedCreateInput) {
    return this.prisma.expense.create({
      data,
      include: {
        category: true,
        subCategory: true,
        expenseType: true,
        spendEntity: true,
        account: true,
        enteredBy: { select: { id: true, name: true } },
      },
    });
  }

  findManyForUser(
    userId: string,
    workspaceId: string,
    where: Prisma.ExpenseWhereInput,
  ) {
    return this.prisma.expense.findMany({
      where: { ...where, userId, workspaceId },
      include: {
        category: true,
        subCategory: true,
        expenseType: true,
        spendEntity: true,
        account: true,
        enteredBy: { select: { id: true, name: true } },
      },
      orderBy: { date: 'desc' },
    });
  }

  findOneForUser(userId: string, workspaceId: string, id: string) {
    return this.prisma.expense.findFirst({
      where: { id, userId, workspaceId },
      include: {
        category: true,
        subCategory: true,
        expenseType: true,
        spendEntity: true,
        account: true,
        enteredBy: { select: { id: true, name: true } },
      },
    });
  }

  updateForUser(userId: string, workspaceId: string, id: string, data: Prisma.ExpenseUncheckedUpdateInput) {
    return this.prisma.expense.updateMany({ where: { id, userId, workspaceId }, data });
  }

  deleteForUser(userId: string, workspaceId: string, id: string) {
    return this.prisma.expense.deleteMany({ where: { id, userId, workspaceId } });
  }
}
