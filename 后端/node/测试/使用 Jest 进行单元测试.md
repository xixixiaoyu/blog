# 使用 Jest 进行单元测试

目标
- 快速搭建 JS/TS 的单元测试，形成基本测试金字塔底座。

依赖安装
```bash
# JS 项目
npm i -D jest

# TS 项目
npm i -D jest ts-jest @types/jest typescript
npx ts-jest config:init
```

示例（JS）：sum.test.js
```js
function sum(a, b) { return a + b; }
test('sum', () => { expect(sum(1, 2)).toBe(3); });
```

运行
```bash
npx jest
```

要点
- 单元测试快而稳；集成测试关注接口契约；端到端模拟用户流程。
- 合理的测试数据构造与隔离（如使用内存数据库或 Docker 临时实例）。

