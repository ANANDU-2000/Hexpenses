import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import sqlite3 from 'sqlite3';

const prisma = new PrismaClient();
const sourcePath = process.env.DJANGO_SOURCE_DB_PATH || path.resolve(__dirname, '../../backend/db.sqlite3');

function all(db: sqlite3.Database, sql: string): Promise<any[]> {
  return new Promise((resolve, reject) => db.all(sql, (err, rows) => (err ? reject(err) : resolve(rows))));
}

async function run() {
  const source = new sqlite3.Database(sourcePath);
  const users = await all(source, 'SELECT id, username FROM auth_user');
  for (const row of users) {
    await prisma.user.upsert({
      where: { phone: `legacy-${row.id}` },
      create: { name: row.username, phone: `legacy-${row.id}`, currency: 'INR' },
      update: { name: row.username },
    });
  }
  const categories = await all(source, 'SELECT id, name, user_id, parent_id FROM expenses_category');
  for (const cat of categories) {
    const user = await prisma.user.findFirst({ where: { phone: `legacy-${cat.user_id}` } });
    if (!user) continue;
    await prisma.category.create({
      data: {
        name: cat.name,
        userId: user.id,
      },
    });
  }
  source.close();
  await prisma.$disconnect();
  console.log('Django to Prisma migration completed.');
}

run().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
