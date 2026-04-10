import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

const publicUserSelect = {
  id: true,
  name: true,
  phone: true,
  email: true,
  currency: true,
  role: true,
  timeZone: true,
  locale: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.UserSelect;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateUserDto) {
    if (!dto.phone?.trim() && !dto.email?.trim()) {
      throw new BadRequestException('User must have phone or email');
    }
    const passwordHash = dto.password ? await bcrypt.hash(dto.password, 12) : undefined;
    return this.prisma.user.create({
      data: {
        name: dto.name,
        phone: dto.phone?.trim() || null,
        email: dto.email?.trim() || null,
        passwordHash,
        currency: dto.currency,
        role: (dto.role as UserRole | undefined) ?? UserRole.owner,
      },
      select: publicUserSelect,
    });
  }

  findAll() {
    return this.prisma.user.findMany({
      where: { deletedAt: null },
      orderBy: { createdAt: 'desc' },
      select: publicUserSelect,
    });
  }

  async getPublicProfile(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: publicUserSelect,
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    const data: Prisma.UserUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.email !== undefined) data.email = dto.email;
    if (dto.timeZone !== undefined) data.timeZone = dto.timeZone;
    if (dto.locale !== undefined) data.locale = dto.locale;
    if (dto.password) data.passwordHash = await bcrypt.hash(dto.password, 12);

    try {
      return await this.prisma.user.update({
        where: { id: userId },
        data,
        select: publicUserSelect,
      });
    } catch {
      throw new NotFoundException('User not found');
    }
  }
}
