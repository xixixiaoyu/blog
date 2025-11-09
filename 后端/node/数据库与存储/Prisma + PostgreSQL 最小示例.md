# Prisma + PostgreSQL 最小示例

目标
- 通过 Prisma 连接 PostgreSQL，完成基本 CRUD。

依赖安装
```bash
npm i @prisma/client
npm i -D prisma tsx typescript
npx prisma init
```

.env
```
DATABASE_URL="postgresql://user:pass@localhost:5432/app?schema=public"
```

schema.prisma
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  createdAt DateTime @default(now())
}
```

迁移与生成
```bash
npx prisma migrate dev --name init
npx prisma generate
```

示例：index.ts
```ts
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const alice = await prisma.user.create({ data: { email: 'alice@example.com', name: 'Alice' } });
  console.log('created', alice);
  const users = await prisma.user.findMany();
  console.log('users', users);
}

main().finally(() => prisma.$disconnect());
```

运行
```bash
npx tsx index.ts
```

要点
- 连接池与事务管理在生产环境尤为关键（Prisma 提供事务 API）。
- 使用迁移管理模式变更，谨防生产直接改 schema。

