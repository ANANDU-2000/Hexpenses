import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

type VehicleRow = Prisma.VehicleGetPayload<{ include: { expenses: true } }>;

function num(d: Prisma.Decimal | null | undefined): number | null {
  if (d === null || d === undefined) return null;
  return Number(d);
}

function serializeVehicle(row: VehicleRow) {
  return {
    id: row.id,
    name: row.name,
    number: row.number,
    vehicleType: row.vehicleType,
    purchaseDate: row.purchaseDate?.toISOString() ?? null,
    purchasePrice: num(row.purchasePrice),
    currentValue: num(row.currentValue),
    insuranceExpiryDate: row.insuranceExpiryDate?.toISOString() ?? null,
    expenses: row.expenses,
  };
}

@Injectable()
export class VehiclesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    const rows = await this.prisma.vehicle.findMany({
      where: { userId },
      include: { expenses: true },
      orderBy: { name: 'asc' },
    });
    return rows.map(serializeVehicle);
  }

  create(userId: string, body: any) {
    const purchaseDate = body.purchaseDate ? new Date(body.purchaseDate) : undefined;
    const insuranceExpiryDate = body.insuranceExpiryDate
      ? new Date(body.insuranceExpiryDate)
      : undefined;
    const purchasePrice =
      body.purchasePrice !== undefined && body.purchasePrice !== null && body.purchasePrice !== ''
        ? new Prisma.Decimal(String(body.purchasePrice))
        : undefined;
    const currentValue =
      body.currentValue !== undefined && body.currentValue !== null && body.currentValue !== ''
        ? new Prisma.Decimal(String(body.currentValue))
        : undefined;

    return this.prisma.vehicle
      .create({
        data: {
          userId,
          name: String(body.name).trim(),
          number: String(body.number).trim(),
          vehicleType: ['car', 'bike', 'other'].includes(String(body.vehicleType))
            ? String(body.vehicleType)
            : 'car',
          purchaseDate: purchaseDate && !Number.isNaN(purchaseDate.getTime()) ? purchaseDate : null,
          purchasePrice: purchasePrice ?? null,
          currentValue: currentValue ?? null,
          insuranceExpiryDate:
            insuranceExpiryDate && !Number.isNaN(insuranceExpiryDate.getTime())
              ? insuranceExpiryDate
              : null,
        },
        include: { expenses: true },
      })
      .then(serializeVehicle);
  }

  async update(userId: string, id: string, body: any) {
    const row = await this.prisma.vehicle.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Vehicle not found');

    const data: Prisma.VehicleUpdateInput = {
      name: String(body.name ?? row.name).trim(),
      number: String(body.number ?? row.number).trim(),
      vehicleType: ['car', 'bike', 'other'].includes(String(body.vehicleType))
        ? String(body.vehicleType)
        : row.vehicleType,
      purchaseDate:
        body.purchaseDate === null || body.purchaseDate === undefined || body.purchaseDate === ''
          ? null
          : new Date(body.purchaseDate),
      insuranceExpiryDate:
        body.insuranceExpiryDate === null ||
        body.insuranceExpiryDate === undefined ||
        body.insuranceExpiryDate === ''
          ? null
          : new Date(body.insuranceExpiryDate),
      purchasePrice:
        body.purchasePrice === null || body.purchasePrice === undefined || body.purchasePrice === ''
          ? null
          : new Prisma.Decimal(String(body.purchasePrice)),
      currentValue:
        body.currentValue === null || body.currentValue === undefined || body.currentValue === ''
          ? null
          : new Prisma.Decimal(String(body.currentValue)),
    };

    const updated = await this.prisma.vehicle.update({
      where: { id },
      data,
      include: { expenses: true },
    });
    return serializeVehicle(updated);
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
