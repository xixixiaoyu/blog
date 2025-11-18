# MySQL 核心基础

后端开发的核心任务之一，是从数据库中检索数据并返回给前端，以及将前端提交的数据持久化到数据库中。因此，掌握数据库知识是后端学习的关键一步。本文将带你从零开始，全面掌握 MySQL 的核心基础。

## 一、环境准备与连接

### 1. 启动 MySQL 服务

我们推荐使用 Docker 来运行 MySQL，这可以避免复杂的本地安装和环境配置。

首先，通过 Docker Desktop 搜索并拉取 MySQL 镜像：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687430043709-45e79ffb-a93b-4aab-a62d-df2d96ea8bf1.png)

拉取成功后，点击 “Run” 运行容器，并配置以下关键参数：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687430319663-469f9825-0db7-429b-9c09-3cba61b5763d.png)

*   **Port**：设置端口映射，将容器的 `3306` 端口（MySQL 默认端口）映射到宿主机的某个端口（例如 `3306`）。
*   **Volume**：设置数据卷挂载，将本机的某个目录挂载到容器的 `/var/lib/mysql` 目录。这是 MySQL 存储数据的地方，这样做可以保证容器被删除后数据不丢失。
*   **Environment Variables**：设置环境变量 `MYSQL_ROOT_PASSWORD`，这是你连接 MySQL 服务器时 root 用户的密码。

配置完成后，点击 “Run”，MySQL 容器就会成功运行。

### 2. 连接 MySQL

你可以通过命令行或图形化界面（GUI）两种方式连接到正在运行的 MySQL 服务器。

#### 命令行工具

MySQL 镜像自带了命令行工具。你可以进入容器的命令行界面：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687430817852-6dc0edc2-fa2e-4c84-afd9-a193d0f9f107.png)

然后使用以下命令连接到 MySQL 服务器，系统会提示你输入之前设置的密码：

```bash
mysql -u root -p
```

#### GUI 客户端工具

对于初学者，我们更推荐使用图形化客户端，因为它更直观、易用。MySQL 官方提供了免费的 GUI 工具：[MySQL Workbench](https://dev.mysql.com/downloads/workbench/)。

安装并打开 MySQL Workbench 后，点击 “+” 号创建一个新的数据库连接：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687431024865-dc48d715-1563-47ef-8f83-4762cc46ee0f.png)

输入连接名、主机（`localhost`）、端口（`3306`）、用户名（`root`），然后点击 “Store in Keychain...” 输入你设置的密码。最后点击 “Test Connection” 测试连接，成功后即可保存并进入操作界面。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1711282866457-efe2e661-bf20-4917-a61d-d4622bd586d4.png)

在主界面的左侧 “SCHEMAS” 标签下，你可以查看和管理所有的数据库（在 MySQL 中，`schema` 和 `database` 是同义词）。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687431393582-021d8cf2-0ea5-46a7-8b66-43c7db4814f1.png)

## 二、SQL 基础与数据类型

SQL (Structured Query Language) 是用于操作关系型数据库的标准化语言。它主要分为三类：

*   **数据定义语言 (DDL - Data Definition Language)**：用于定义和管理数据库对象。
    *   `CREATE`：创建数据库、表等。
    *   `ALTER`：修改表结构。
    *   `DROP`：删除数据库、表。
*   **数据操作语言 (DML - Data Manipulation Language)**：用于操作表中的数据。
    *   `INSERT`：插入数据。
    *   `UPDATE`：更新数据。
    *   `DELETE`：删除数据。
*   **数据查询语言 (DQL - Data Query Language)**：用于查询数据，主要是 `SELECT` 语句。

### 1. 常用数据类型

在创建表时，你需要为每一列指定合适的数据类型。以下是一些最常用的数据类型：

| 大类 | 类型 | 描述 | 示例 |
| :--- | :--- | :--- | :--- |
| **数值类型** | `INT` | 标准整数，用于存储年龄、数量等。 | `25` |
| | `BIGINT` | 大整数，用于存储需要更大范围的整数。 | `10000000000` |
| | `DOUBLE` | 双精度浮点数，用于存储小数。 | `19.99` |
| | `DECIMAL` | 精确的小数，常用于财务计算，避免精度丢失。 | `DECIMAL(10, 2)` |
| **字符串类型** | `VARCHAR(n)` | 变长字符串，`n` 是最大长度。 | `VARCHAR(100)` |
| | `CHAR(n)` | 定长字符串，长度不足时会用空格填充。 | `CHAR(10)` |
| | `TEXT` | 用于存储长文本，如文章内容。 | |
| **日期和时间** | `DATE` | 仅存储日期。 | `2023-10-26` |
| | `TIME` | 仅存储时间。 | `14:30:00` |
| | `DATETIME` | 存储日期和时间。 | `2023-10-26 14:30:00` |
| | `TIMESTAMP` | 存储日期和时间，并与时区相关，常用于记录创建/更新时间。 | |

### 2. 创建数据库和表

你可以使用 DDL 语句来创建数据库和表。

**创建数据库**：

```sql
CREATE DATABASE `hello-mysql` DEFAULT CHARACTER SET utf8mb4;
```

**创建表**：

我们来创建一个 `student` 表作为示例。

```sql
CREATE TABLE `student` (
  `id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Id',
  `name` VARCHAR(50) NOT NULL COMMENT '学生名',
  `gender` VARCHAR(10) NOT NULL COMMENT '性别',
  `age` INT NOT NULL COMMENT '年龄',
  `class` VARCHAR(50) NOT NULL COMMENT '班级名',
  `score` INT NOT NULL COMMENT '分数'
) DEFAULT CHARSET=utf8mb4;
```

*   `PRIMARY KEY`：**主键**，唯一标识表中的每一行，值不能重复且不能为空。
*   `AUTO_INCREMENT`：**自动递增**，当你插入新数据时，数据库会自动为该列分配一个递增的唯一值。
*   `NOT NULL`：**非空约束**，表示该列在插入或更新时必须有值。
*   `COMMENT`：为列添加注释，方便理解。

## 三、数据操作与查询 (DML & DQL)

### 1. 插入数据 (INSERT)

使用 `INSERT INTO` 语句向表中添加新记录。

```sql
INSERT INTO `student` (name, gender, age, class, score)
VALUES 
    ('张三', '男', 18, '一班', 85),
    ('李四', '女', 19, '二班', 86),
    ('王五', '男', 20, '三班', 87),
    ('赵六', '女', 21, '一班', 88);
```

### 2. 更新数据 (UPDATE)

使用 `UPDATE` 语句修改表中的现有记录，通常需要配合 `WHERE` 子句来指定要更新的行。

```sql
-- 将名为“张三”的学生的班级更新为“精英班”
UPDATE `student` SET `class` = '精英班' WHERE `name` = '张三';
```

**警告**：如果没有 `WHERE` 子句，`UPDATE` 将会更新表中的所有行！

### 3. 删除数据 (DELETE)

使用 `DELETE FROM` 语句删除表中的记录，同样需要配合 `WHERE` 子句。

```sql
-- 删除名为“赵六”的学生记录
DELETE FROM `student` WHERE `name` = '赵六';
```

**警告**：如果没有 `WHERE` 子句，`DELETE` 将会删除表中的所有行！

### 4. 查询数据 (SELECT)

`SELECT` 是 SQL 中最强大、最常用的语句。

#### 基础查询

```sql
-- 查询所有学生的所有信息
SELECT * FROM `student`;

-- 查询指定列（姓名和分数），并使用 AS 给列起别名
SELECT `name` AS `名字`, `score` AS `分数` FROM `student`;
```

#### 条件查询 (WHERE)

使用 `WHERE` 子句过滤出满足特定条件的记录。

```sql
-- 查询年龄大于等于 20 岁的学生
SELECT * FROM `student` WHERE `age` >= 20;

-- 查询“一班”中分数大于 85 分的学生 (使用 AND 连接多个条件)
SELECT * FROM `student` WHERE `class` = '一班' AND `score` > 85;
```

#### 特殊查询

*   **模糊查询 (`LIKE`)**：`%` 代表零个或多个任意字符。
    ```sql
    -- 查询所有姓“张”的学生
    SELECT * FROM `student` WHERE `name` LIKE '张%';
    ```

*   **范围查询 (`BETWEEN...AND...`)**：选取介于两个值之间的数据范围。
    ```sql
    -- 查询年龄在 19 到 21 岁之间的学生
    SELECT * FROM `student` WHERE `age` BETWEEN 19 AND 21;
    ```

*   **列表查询 (`IN`)**：匹配列表中的多个值。
    ```sql
    -- 查询“一班”和“三班”的所有学生
    SELECT * FROM `student` WHERE `class` IN ('一班', '三班');
    ```

#### 结果排序 (ORDER BY)

使用 `ORDER BY` 对查询结果进行排序。

```sql
-- 按分数降序 (DESC) 排序，如果分数相同，则按年龄升序 (ASC) 排序
SELECT `name`, `score`, `age` FROM `student` ORDER BY `score` DESC, `age` ASC;
```

#### 分页查询 (LIMIT)

在实际应用中，数据量可能很大，需要进行分页展示。`LIMIT` 子句可以限制返回的记录数量。

```sql
-- 查询前 5 条记录 (第一页)
SELECT * FROM `student` LIMIT 0, 5;

-- 从第 5 条记录开始，查询 5 条记录 (第二页)
SELECT * FROM `student` LIMIT 5, 5;
```

#### 分组与聚合 (GROUP BY)

`GROUP BY` 语句通常与聚合函数一起使用，将具有相同值的行组合成一个组，并对每个组进行计算。

常用的聚合函数：
*   `COUNT()`: 计数组内记录的数量。
*   `SUM()`: 计算组内某列的总和。
*   `AVG()`: 计算组内某列的平均值。
*   `MAX()`: 找出组内某列的最大值。
*   `MIN()`: 找出组内某列的最小值。

```sql
-- 计算每个班级的平均分，并按平均分降序排列
SELECT `class`, AVG(`score`) AS `平均分`
FROM `student`
GROUP BY `class`
ORDER BY `平均分` DESC;
```

#### 分组后过滤 (HAVING)

`WHERE` 用于在分组前过滤记录，而 `HAVING` 用于在分组后过滤结果。

```sql
-- 查询平均分超过 87 分的班级
SELECT `class`, AVG(`score`) AS `平均分`
FROM `student`
GROUP BY `class`
HAVING `平均分` > 87;
```

## 四、数据库关系设计

在真实世界的应用中，数据通常分散在多个表中，这些表通过“关系”相互连接。

### 1. 关系类型

*   **一对一 (One-to-One)**：一个实体最多只能与另一个实体的一条记录相关联。例如，一个用户只有一个身份证信息。
*   **一对多 (One-to-Many)**：一个实体可以与另一个实体的多条记录相关联。例如，一个部门可以有多名员工。
*   **多对多 (Many-to-Many)**：两个实体的记录可以相互拥有多个关联。例如，一篇文章可以有多个标签，一个标签也可以用于多篇文章。

### 2. 外键 (Foreign Key)

**外键**是实现表之间关系的核心。它是一个表中的列，其值引用了另一个表的主键。

### 3. 一对一关系实现

在 `id_card` 表中添加一个外键 `user_id`，引用 `user` 表的 `id`。

**`user` 表**:
```sql
CREATE TABLE `user` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL
);
```

**`id_card` 表**:
```sql
CREATE TABLE `id_card` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `card_name` VARCHAR(50) NOT NULL,
  `user_id` INT UNIQUE, -- UNIQUE 约束保证一个 user_id 只出现一次
  FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
);
```

### 4. 一对多关系实现

在“多”的一方（`employee` 表）添加一个外键，引用“一”的一方（`department` 表）的主键。

**`department` 表**:
```sql
CREATE TABLE `department` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL
);
```

**`employee` 表**:
```sql
CREATE TABLE `employee` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `department_id` INT,
  FOREIGN KEY (`department_id`) REFERENCES `department`(`id`)
);
```

### 5. 多对多关系实现

多对多关系需要通过一个**中间表**（也叫连接表）来实现。这个表至少包含两个外键，分别引用另外两个表的主键。

**`article` 表**:
```sql
CREATE TABLE `article` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `title` VARCHAR(100) NOT NULL
);
```

**`tag` 表**:
```sql
CREATE TABLE `tag` (
  `id` INT PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL
);
```

**中间表 `article_tag`**:
```sql
CREATE TABLE `article_tag` (
  `article_id` INT NOT NULL,
  `tag_id` INT NOT NULL,
  PRIMARY KEY (`article_id`, `tag_id`), -- 复合主键，确保同一篇文章和标签的组合是唯一的
  FOREIGN KEY (`article_id`) REFERENCES `article`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`tag_id`) REFERENCES `tag`(`id`) ON DELETE CASCADE
);
```
*   `ON DELETE CASCADE`：这是一个**级联操作**。当主表（如 `article`）中的记录被删除时，中间表中所有引用该记录的行也会被自动删除，以维护数据的一致性。

### 6. 多表关联查询 (JOIN)

当需要从多个关联的表中获取数据时，就需要使用 `JOIN` 语句。

*   **`INNER JOIN` (内连接)**：只返回两个表中能通过连接条件匹配上的记录。
*   **`LEFT JOIN` (左连接)**：返回左表的所有记录，以及右表中匹配上的记录。如果右表没有匹配项，则右表的列显示为 `NULL`。
*   **`RIGHT JOIN` (右连接)**：返回右表的所有记录，以及左表中匹配上的记录。如果左表没有匹配项，则左表的列显示为 `NULL`。

**示例：查询用户及其身份证信息 (一对一)**
```sql
SELECT u.name, ic.card_name
FROM `user` u
INNER JOIN `id_card` ic ON u.id = ic.user_id;
```

**示例：查询部门及其所有员工 (一对多)**
```sql
SELECT d.name AS `部门`, e.name AS `员工`
FROM `department` d
LEFT JOIN `employee` e ON d.id = e.department_id;
```

**示例：查询文章及其所有标签 (多对多)**
```sql
SELECT a.title, t.name
FROM `article` a
JOIN `article_tag` at ON a.id = at.article_id
JOIN `tag` t ON at.tag_id = t.id
WHERE a.id = 1; -- 查询 ID 为 1 的文章的所有标签
```
