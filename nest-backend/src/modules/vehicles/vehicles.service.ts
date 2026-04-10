import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class VehiclesService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.vehicle.findMany({ where: { userId }, include: { expenses: true } });
  }

  create(userId: string, body: any) {
    return this.prisma.vehicle.create({
      data: { userId, name: body.name, number: body.number },
    });
  }

  addExpense(vehicleId: string, body: any) {
    return this.prisma.vehicleExpense.create({
      data: {
        vehicleId,
        type: body.type,
        amount: body.amount,
        date: new Date(body.date),
      },
    });
  }

  async totalCost(vehicleId: string) {
    const rows = await this.prisma.vehicleExpense.findMany({ where: { vehicleId } });
    const total = rows.reduce((sum: number, row: { amount: unknown }) => sum + Number(row.amount), 0);
    return { vehicleId, totalCost: total.toFixed(2) };
  }
}
