# MySQL 进阶与应用

在掌握了 MySQL 的基础操作和关系设计之后，本篇将带你深入学习更高级的 SQL技巧、事务处理、数据库对象，并最终探索如何在 Node.js 项目中应用 MySQL。

## 一、高级 SQL 查询

### 1. 子查询

子查询（Subquery）是指嵌套在另一个 SQL 查询语句中的查询。它能够处理更复杂的查询逻辑。

**示例 1：查询分数最高的学生**

```sql
-- 外部查询利用内部查询的结果 (最高分) 作为过滤条件
SELECT `name`, `score`
FROM `student`
WHERE `score` = (SELECT MAX(`score`) FROM `student`);
```

**示例 2：查询分数高于平均分的学生**

```sql
SELECT `name`, `score`
FROM `student`
WHERE `score` > (SELECT AVG(`score`) FROM `student`);
```

### 2. EXISTS 与 NOT EXISTS

`EXISTS` 用于检查子查询是否返回任何行。如果子查询返回至少一行，`EXISTS` 的结果就为 `TRUE`；否则为 `FALSE`。`NOT EXISTS` 则相反。它比 `IN` 在某些场景下效率更高。

**示例：查询所有有订单记录的客户**

```sql
SELECT `name`
FROM `customers` c
WHERE EXISTS (
  SELECT 1 FROM `orders` o WHERE o.customer_id = c.id
);
```
这里，对于 `customers` 表中的每一行，都会执行子查询。如果能找到匹配的订单，`EXISTS` 就返回 `TRUE`，该客户被选中。

### 3. 常用函数

SQL 提供了丰富的内置函数来处理数据。

#### 字符串函数

| 函数 | 描述 | 示例 |
| :--- | :--- | :--- |
| `CONCAT()` | 连接两个或多个字符串。 | `CONCAT(name, '(', class, ')')` |
| `SUBSTR()` | 提取字符串的子串。 | `SUBSTR(name, 1, 1)` (提取姓) |
| `LENGTH()` | 返回字符串的字节长度。 | `LENGTH(name)` |
| `UPPER()`/`LOWER()` | 转换为大写/小写。 | `UPPER('hello')` |

#### 数值函数

| 函数 | 描述 | 示例 |
| :--- | :--- | :--- |
| `ROUND()` | 四舍五入到指定小数位数。 | `ROUND(1.2345, 2)` (结果: 1.23) |
| `CEIL()` | 向上取整。 | `CEIL(1.23)` (结果: 2) |
| `FLOOR()` | 向下取整。 | `FLOOR(1.23)` (结果: 1) |
| `ABS()` | 返回绝对值。 | `ABS(-10)` (结果: 10) |
| `MOD()` | 返回取模（余数）结果。 | `MOD(5, 2)` (结果: 1) |

#### 日期与时间函数

| 函数 | 描述 | 示例 |
| :--- | :--- | :--- |
| `NOW()` | 返回当前日期和时间。 | |
| `YEAR()`/`MONTH()`/`DAY()` | 提取年/月/日。 | `YEAR('2023-10-26')` |
| `DATE_FORMAT()` | 将日期格式化为字符串。 | `DATE_FORMAT(NOW(), '%Y年%m月%d日')` |
| `STR_TO_DATE()` | 将字符串解析为日期。 | `STR_TO_DATE('2023-10-26', '%Y-%m-%d')` |

#### 条件函数

*   **`IF(condition, value_if_true, value_if_false)`**
    ```sql
    SELECT `name`, IF(`score` >= 60, '及格', '不及格') AS `状态` FROM `student`;
    ```

*   **`CASE` 表达式**：用于处理更复杂的条件逻辑。
    ```sql
    SELECT `name`, `score`,
           CASE
               WHEN `score` >= 90 THEN '优秀'
               WHEN `score` >= 80 THEN '良好'
               WHEN `score` >= 60 THEN '及格'
               ELSE '不及格'
           END AS `等级`
    FROM `student`;
    ```

### 4. 类型转换 (CAST & CONVERT)

在进行比较或计算时，有时需要明确地转换数据类型。

```sql
-- 字符串 '123' 会被隐式转换为数字进行比较
SELECT GREATEST(1, '123', 3); -- 结果是 123

-- 使用 CAST 显式转换，更规范
SELECT GREATEST(1, CAST('123' AS SIGNED), 3);
```
支持的类型包括 `SIGNED` (整数), `DECIMAL` (浮点数), `CHAR` (字符串), `DATE`, `TIME`, `DATETIME` 等。

## 二、事务与隔离级别

### 1. 事务的基本概念

**事务 (Transaction)** 是一组原子性的 SQL 操作单元，这组操作要么全部成功执行，要么全部失败回滚。事务确保了数据的一致性。

**基本语法**：
*   `START TRANSACTION;`：开启一个新事务。
*   `COMMIT;`：提交事务，将所有更改永久保存到数据库。
*   `ROLLBACK;`：回滚事务，撤销当前事务中的所有更改。

**示例**：银行转账
```sql
START TRANSACTION;

-- 张三账户减 100
UPDATE `accounts` SET `balance` = `balance` - 100 WHERE `user` = '张三';

-- 李四账户加 100
UPDATE `accounts` SET `balance` = `balance` + 100 WHERE `user` = '李四';

-- 如果中间出现任何错误，可以执行 ROLLBACK;
-- 如果一切顺利，执行 COMMIT;
COMMIT;
```

### 2. 并发问题

当多个事务同时访问同一份数据时，可能会出现以下问题：

*   **脏读 (Dirty Read)**：一个事务读取了另一个事务**未提交**的数据。如果那个事务最终回滚，那么读取到的就是无效的“脏”数据。
*   **不可重复读 (Non-repeatable Read)**：在一个事务内，两次读取同一行数据，但结果不同。这是因为在两次读取之间，有另一个事务**修改**了这行数据并提交了。
*   **幻读 (Phantom Read)**：在一个事务内，两次执行相同的范围查询，但返回的记录数不同。这是因为在两次查询之间，有另一个事务**插入或删除**了符合条件的记录。

### 3. 事务隔离级别

为了解决并发问题，MySQL 提供了四种隔离级别，隔离程度从低到高：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
| :--- | :--- | :--- | :--- |
| **READ UNCOMMITTED (未提交读)** | 可能 | 可能 | 可能 |
| **READ COMMITTED (提交读)** | 不可能 | 可能 | 可能 |
| **REPEATABLE READ (可重复读)** | 不可能 | 不可能 | 可能 |
| **SERIALIZABLE (可串行化)** | 不可能 | 不可能 | 不可能 |

*   **`REPEATABLE READ`** 是 MySQL 的默认隔离级别。它通过多版本并发控制 (MVCC) 解决了不可重复读问题，但在一定程度上仍然可能出现幻读。
*   **`SERIALIZABLE`** 是最高的隔离级别，它强制事务串行执行，完全避免了所有并发问题，但性能最差。

**查询和设置隔离级别**：
```sql
-- 查询当前会话的隔离级别
SELECT @@transaction_isolation;

-- 设置当前会话的隔离级别
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

## 三、高级数据库对象

### 1. 视图 (View)

**视图**是一个虚拟表，其内容由一个 SQL 查询定义。它就像一个窗口，通过它我们可以看到底层表的数据，但可以进行简化、筛选和重组。

**优点**：
*   **简化复杂查询**：将复杂的多表 JOIN 查询封装成一个简单的视图。
*   **增强安全性**：可以只向用户暴露视图，隐藏底层表的结构和部分敏感数据。

**创建视图**：
```sql
CREATE VIEW `v_customer_orders` AS
SELECT
    c.name AS customer_name,
    o.id AS order_id,
    o.order_date,
    oi.product_name,
    oi.quantity,
    oi.price
FROM `customers` c
JOIN `orders` o ON c.id = o.customer_id
JOIN `order_items` oi ON o.id = oi.order_id;
```
之后，你可以像查询普通表一样查询这个视图：`SELECT * FROM v_customer_orders WHERE customer_name = '张三';`

### 2. 存储过程 (Stored Procedure)

**存储过程**是预先编译好并存储在数据库中的一组 SQL 语句。它可以接收参数，执行复杂的业务逻辑。

**优点**：
*   **封装业务逻辑**：将复杂的业务操作封装在数据库层面。
*   **减少网络传输**：客户端只需调用一个存储过程，而不是发送多条 SQL 语句。
*   **提高性能**：存储过程是预编译的，执行效率更高。

**创建存储过程**：
```sql
-- 临时修改语句分隔符，以便在过程中使用分号
DELIMITER $$

CREATE PROCEDURE `get_orders_by_customer`(IN customerId INT)
BEGIN
    SELECT * FROM `orders` WHERE `customer_id` = customerId;
END$$

-- 恢复默认分隔符
DELIMITER ;
```
**调用存储过程**：
```sql
CALL get_orders_by_customer(1);
```

### 3. 函数 (Function)

**函数**与存储过程类似，也是一段预存的代码，但它**必须返回一个值**。函数通常用于计算。

**创建函数**：
```sql
DELIMITER $$

CREATE FUNCTION `get_order_total_amount`(orderId INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC -- 指明函数是确定性的
BEGIN
    DECLARE total DECIMAL(10, 2);
    SELECT SUM(`quantity` * `price`) INTO total
    FROM `order_items`
    WHERE `order_id` = orderId;
    RETURN total;
END$$

DELIMITER ;
```
**调用函数**：
函数可以直接在 `SELECT` 语句中使用。
```sql
SELECT id, get_order_total_amount(id) AS total FROM `orders`;
```

## 四、在 Node.js 中操作 MySQL

### 1. 使用 `mysql2` 库

`mysql2` 是一个流行的 Node.js 驱动，性能比官方的 `mysql` 库更好，并且支持 Promise API。

**安装**：
```bash
npm install mysql2
```

**连接与查询**：
推荐使用连接池 (`createPool`) 来管理数据库连接，以提高性能和稳定性。

```javascript
const mysql = require('mysql2/promise');

// 创建连接池
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'your_password',
  database: 'practice',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 异步查询
async function getUsers() {
  try {
    const [rows, fields] = await pool.query('SELECT * FROM `users`');
    console.log(rows);
  } catch (err) {
    console.error(err);
  }
}

getUsers();
```

**参数化查询**：
为了防止 SQL 注入，应始终使用参数化查询（占位符 `?`）。

```javascript
const userId = 1;
const [rows] = await pool.execute('SELECT * FROM `users` WHERE `id` = ?', [userId]);
```

### 2. 使用 TypeORM (ORM 框架)

**ORM (Object-Relational Mapping)** 允许你使用面向对象的方式来操作数据库，而无需编写原生 SQL 语句。TypeORM 是 TypeScript/JavaScript 中一个成熟的 ORM 框架。

**核心思想**：将数据库中的**表 (Table)** 映射为代码中的**类 (Class)**，将**行 (Row)** 映射为**实例 (Instance)**，将**列 (Column)** 映射为**属性 (Property)**。

**安装与初始化**：
```bash
npm install typeorm reflect-metadata mysql2
npx typeorm init --name my-project --database mysql
```

**配置数据源 (`data-source.ts`)**：
```typescript
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
    type: 'mysql',
    host: 'localhost',
    port: 3306,
    username: 'root',
    password: 'your_password',
    database: 'practice',
    synchronize: true, // 自动根据实体类同步数据库表结构（仅限开发环境）
    logging: false,
    entities: ['src/entity/**/*.ts'], // 实体类路径
});
```

**定义实体 (`src/entity/User.ts`)**：
```typescript
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class User {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    firstName: string;

    @Column()
    lastName: string;

    @Column({ default: true })
    isActive: boolean;
}
```

**操作数据库**：
```typescript
import { AppDataSource } from './data-source';
import { User } from './entity/User';

AppDataSource.initialize()
    .then(async () => {
        console.log('Data Source has been initialized!');

        const userRepository = AppDataSource.getRepository(User);

        // 创建
        const user = new User();
        user.firstName = 'Timber';
        user.lastName = 'Saw';
        await userRepository.save(user);
        console.log('Saved a new user with id: ' + user.id);

        // 查询
        const users = await userRepository.find();
        console.log('Loaded users: ', users);

        // 更新
        const userToUpdate = await userRepository.findOneBy({ id: 1 });
        if (userToUpdate) {
            userToUpdate.firstName = 'Timber Updated';
            await userRepository.save(userToUpdate);
        }

        // 删除
        await userRepository.remove(user);

    })
    .catch((err) => {
        console.error('Error during Data Source initialization:', err);
    });
```

使用 ORM 可以极大地提高开发效率，使代码更易于维护，并能方便地在不同数据库之间切换。

## 五、SQL 综合练习

下面我们通过一个综合案例来实践前面学到的知识。

**场景**：一个简单的电商系统，包含客户 (`customers`)、订单 (`orders`) 和订单项 (`order_items`) 三张表。

### 1. 表结构

```sql
-- 客户表
CREATE TABLE `customers` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL
);

-- 订单表
CREATE TABLE `orders` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `order_date` DATE NOT NULL,
  `total_amount` DECIMAL(10, 2) NOT NULL,
  FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`)
);

-- 订单项表
CREATE TABLE `order_items` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `product_name` VARCHAR(255) NOT NULL,
  `quantity` INT NOT NULL,
  `price` DECIMAL(10, 2) NOT NULL,
  FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`)
);
```

### 2. 练习需求

**需求 1：查询每个客户的订单总金额，并按金额降序排列。**

```sql
SELECT
    c.name,
    SUM(o.total_amount) AS total_spent
FROM `customers` c
JOIN `orders` o ON c.id = o.customer_id
GROUP BY c.id, c.name
ORDER BY total_spent DESC;
```

**需求 2：查询购买过“耐克篮球鞋”的所有客户。**

```sql
SELECT DISTINCT c.name
FROM `customers` c
JOIN `orders` o ON c.id = o.customer_id
JOIN `order_items` oi ON o.id = oi.order_id
WHERE oi.product_name = '耐克篮球鞋';
```

**需求 3：查询没有下过任何订单的客户。**

```sql
SELECT c.name
FROM `customers` c
LEFT JOIN `orders` o ON c.id = o.customer_id
WHERE o.id IS NULL;
```

**需求 4：查询每个客户的最近一次下单日期。**

```sql
SELECT
    c.name,
    MAX(o.order_date) AS last_order_date
FROM `customers` c
JOIN `orders` o ON c.id = o.customer_id
GROUP BY c.id, c.name;
```

**需求 5：查询订单商品种类超过 2 种的订单 ID。**

```sql
SELECT order_id
FROM `order_items`
GROUP BY order_id
HAVING COUNT(DISTINCT product_name) > 2;
```
