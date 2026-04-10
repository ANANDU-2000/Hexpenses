import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import sqlite3 from 'sqlite3';

const prisma = new PrismaClient();
const sourcePath = process.env.DJANGO_SOURCE_DB_PATH || path.resolve(__dirname, '../../backend/db.sqlite3');

function count(db: sqlite3.Database, table: string): Promise<number> {
  return new Promise((resolve, reject) =>
    db.get(`SELECT COUNT(*) as c FROM ${table}`, (err, row: { c: number }) => (err ? reject(err) : resolve(row.c))),
  );
}

async function run() {
  const source = new sqlite3.Database(sourcePath);
  const [djangoUsers, djangoCategories] = await Promise.all([
    count(source, 'auth_user'),
    count(source, 'expenses_category'),
  ]);
  const [nestUsers, nestCategories] = await Promise.all([
    prisma.user.count(),
    prisma.category.count(),
  ]);
  console.log({ djangoUsers, nestUsers, djangoCategories, nestCategories });
  source.close();
  await prisma.$disconnect();
}

run().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
