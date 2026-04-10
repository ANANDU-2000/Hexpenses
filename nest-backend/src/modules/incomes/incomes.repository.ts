import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

const incomeInclude = { account: true } satisfies Prisma.IncomeInclude;

export type IncomeWithAccount = Prisma.IncomeGetPayload<{ include: typeof incomeInclude }>;

@Injectable()
export class IncomesRepository {
  constructor(private readonly prisma: PrismaService) {}

  findManyForWorkspace(
    userId: string,
    workspaceId: string,
    where: Prisma.IncomeWhereInput,
  ) {
    return this.prisma.income.findMany({
      where: {
        userId,
        ...where,
        account: { workspaceId },
      },
      include: incomeInclude,
      orderBy: { date: 'desc' },
    });
  }

  findOneForWorkspace(userId: string, workspaceId: string, id: string) {
    return this.prisma.income.findFirst({
      where: { id, userId, account: { workspaceId } },
      include: incomeInclude,
    });
  }
}
