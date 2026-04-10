import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateLiabilityDto } from './dto/create-liability.dto';
import { UpdateLiabilityDto } from './dto/update-liability.dto';

@Injectable()
export class LiabilitiesService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.liability.findMany({
      where: { userId },
      orderBy: { name: 'asc' },
    });
  }

  create(userId: string, dto: CreateLiabilityDto) {
    return this.prisma.liability.create({
      data: {
        userId,
        name: dto.name.trim(),
        balance: dto.balance,
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateLiabilityDto) {
    const row = await this.prisma.liability.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Liability not found');
    return this.prisma.liability.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.balance !== undefined ? { balance: dto.balance } : {}),
      },
    });
  }

  async remove(userId: string, id: string) {
    const row = await this.prisma.liability.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Liability not found');
    await this.prisma.liability.delete({ where: { id } });
    return { deleted: true };
  }
}
